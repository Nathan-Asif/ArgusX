#!/usr/bin/env python3
"""
ArgusX desktop HUD simulator — Pygame + OpenCV camera feed.

Connects to the FastAPI WebSocket (/ws/pulse), sends telemetry + frames,
and renders a Flutter-like HUD until the mobile app is ready.

Usage (from Backend/):
  uv pip install -r requirements-simulator.txt
  .\\start_servers.ps1
  uv run python scripts/argusx_hud_simulator.py

Keys:
  1-5     Switch fixture scenario (camera off, uses fixture:* tokens)
  D       Start live Google navigation: Nazimabad -> Saddar
  R       Refresh Google route from current GPS position
  N       Stop navigation mode
  C       Toggle live webcam vs fixture mode
  Arrows  Nudge GPS coordinates (use R to refresh route after moving)
  +/-     Adjust speed
  SPACE   Force immediate pulse
  ESC     Quit
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import json
import queue
import sys
import threading
import time
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import cv2
import numpy as np
import pygame
import websockets

_SCRIPTS_DIR = Path(__file__).resolve().parent
if str(_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_DIR))

from simulator.argusx_map_panel import ArgusXMapPanel  # noqa: E402
from simulator.argusx_nav_arrow import ArgusXNavArrow  # noqa: E402
from simulator.argusx_route_client import ArgusXRouteClient  # noqa: E402
from simulator.argusx_static_map import fetch_static_map_surface  # noqa: E402

DEFAULT_WS = "ws://127.0.0.1:8000/ws/pulse"
DEFAULT_API = "http://127.0.0.1:8000"
FIXTURES_PATH = _SCRIPTS_DIR / "fixtures" / "spatial_zones.json"
KARACHI_NAV_PATH = _SCRIPTS_DIR / "fixtures" / "karachi_navigation.json"

# Desktop has no GPS - Google Geocoding resolves these place names to real coordinates.
DEFAULT_ORIGIN = {"label": "Nazimabad, Karachi"}
DEFAULT_DESTINATION = {"label": "Saddar, Karachi"}

SCENARIOS = {
    pygame.K_1: ("fixture:normal_clear", "Normal — clear road"),
    pygame.K_2: ("fixture:warning_cross_traffic", "Warning — cross traffic"),
    pygame.K_3: ("fixture:warning_opening_door", "Warning — opening door"),
    pygame.K_4: ("fixture:critical_debris", "Critical — road debris"),
    pygame.K_5: ("fixture:critical_pedestrian", "Critical — pedestrian"),
}

THREAT_RING = {
    "NORMAL": (34, 197, 94),
    "WARNING": (234, 179, 8),
    "CRITICAL": (239, 68, 68),
}


def ws_to_api_base(ws_url: str) -> str:
    parsed = urlparse(ws_url)
    scheme = "https" if parsed.scheme == "wss" else "http"
    host = parsed.hostname or "127.0.0.1"
    port = parsed.port or (443 if scheme == "https" else 8000)
    return f"{scheme}://{host}:{port}"


def load_spatial_zones() -> list[dict[str, Any]]:
    if FIXTURES_PATH.exists():
        data = json.loads(FIXTURES_PATH.read_text(encoding="utf-8"))
        return list(data.get("zones", []))
    return []


def frame_to_base64(frame_bgr) -> str:
    ok, buf = cv2.imencode(".jpg", frame_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), 70])
    if not ok:
        return ""
    return base64.b64encode(buf.tobytes()).decode("ascii")


class WebSocketWorker:
    """Background asyncio client; pushes latest pulse responses to a thread-safe queue."""

    def __init__(self, url: str) -> None:
        self.url = url
        self._send_queue: queue.Queue[dict[str, Any]] = queue.Queue()
        self._response_queue: queue.Queue[dict[str, Any]] = queue.Queue(maxsize=4)
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self.connected = False
        self.last_error: str | None = None

    def start(self) -> None:
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()

    def enqueue_pulse(self, payload: dict[str, Any]) -> None:
        while not self._send_queue.empty():
            try:
                self._send_queue.get_nowait()
            except queue.Empty:
                break
        self._send_queue.put(payload)

    def latest_response(self) -> dict[str, Any] | None:
        latest = None
        while True:
            try:
                latest = self._response_queue.get_nowait()
            except queue.Empty:
                break
        return latest

    def _run(self) -> None:
        asyncio.run(self._async_loop())

    async def _async_loop(self) -> None:
        while not self._stop.is_set():
            try:
                async with websockets.connect(self.url, ping_interval=20, ping_timeout=20) as ws:
                    self.connected = True
                    self.last_error = None
                    while not self._stop.is_set():
                        try:
                            payload = self._send_queue.get(timeout=0.05)
                        except queue.Empty:
                            await asyncio.sleep(0.02)
                            continue
                        await ws.send(json.dumps(payload))
                        raw = await asyncio.wait_for(ws.recv(), timeout=30.0)
                        data = json.loads(raw)
                        if self._response_queue.full():
                            try:
                                self._response_queue.get_nowait()
                            except queue.Empty:
                                pass
                        self._response_queue.put(data)
            except Exception as exc:  # noqa: BLE001
                self.connected = False
                self.last_error = str(exc)
                await asyncio.sleep(2.0)


class GoogleRouteWorker:
    """Resolves routes via POST /navigation/resolve without blocking the HUD loop."""

    def __init__(self, route_client: ArgusXRouteClient) -> None:
        self._client = route_client
        self._request_queue: queue.Queue[tuple[dict, dict, int] | None] = queue.Queue()
        self._result_queue: queue.Queue[dict[str, Any]] = queue.Queue(maxsize=2)
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self.resolving = False
        self.last_error: str | None = None

    def start(self) -> None:
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        self._request_queue.put(None)

    def request_resolve(
        self,
        origin: dict[str, Any],
        destination: dict[str, Any],
        *,
        step_index: int = 0,
    ) -> None:
        self.resolving = True
        self.last_error = None
        self._request_queue.put((origin, destination, step_index))

    def latest_result(self) -> dict[str, Any] | None:
        latest = None
        while True:
            try:
                latest = self._result_queue.get_nowait()
            except queue.Empty:
                break
        return latest

    def _run(self) -> None:
        while not self._stop.is_set():
            try:
                item = self._request_queue.get(timeout=0.1)
            except queue.Empty:
                continue
            if item is None:
                break
            origin, destination, step_index = item
            try:
                data = self._client.resolve(origin, destination, step_index=step_index)
                self._result_queue.put({"ok": True, "data": data})
                self.last_error = None
            except Exception as exc:  # noqa: BLE001
                self._result_queue.put({"ok": False, "error": str(exc)})
                self.last_error = str(exc)
            finally:
                self.resolving = False


class ArgusXHudSimulator:
    def __init__(self, ws_url: str, api_base: str, width: int = 1280, height: int = 720) -> None:
        pygame.init()
        self.width = width
        self.height = height
        self.screen = pygame.display.set_mode((width, height))
        pygame.display.set_caption("ArgusX HUD Simulator — Google Maps + Safety Pulse")
        self.clock = pygame.time.Clock()
        self.font = pygame.font.SysFont("consolas", 15)
        self.small_font = pygame.font.SysFont("consolas", 12)

        self.map_panel = ArgusXMapPanel()
        self.nav_arrow = ArgusXNavArrow()
        self.zones = load_spatial_zones()

        self.ws = WebSocketWorker(ws_url)
        self.ws.start()

        self.route_worker = GoogleRouteWorker(ArgusXRouteClient(api_base))
        self.route_worker.start()

        self.lat = 37.7749
        self.lng = -122.4194
        self.speed = 28.0
        self.use_camera = True
        self.fixture_token = "fixture:normal_clear"
        self.scenario_label = "Live camera (or placeholder)"
        self.last_pulse = 0.0
        self.pulse_interval = 2.5
        self.force_pulse = False

        self.last_response: dict[str, Any] = {}
        self.navigation_active = False
        self.destination: dict[str, Any] = DEFAULT_DESTINATION.copy()
        self.route_context: dict[str, Any] | None = None
        self.route_visualization: dict[str, Any] | None = None
        self.origin: dict[str, Any] = DEFAULT_ORIGIN.copy()
        self.nav_status = "Press D - Google nav Nazimabad to Saddar (simulated GPS on PC)"

        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            self.use_camera = False
            self.scenario_label = "No webcam — using fixtures (press 1-5)"

    def _start_google_navigation(self, *, refresh: bool = False) -> None:
        if not refresh:
            self.navigation_active = True
            self.use_camera = False
            self.fixture_token = "fixture:normal_clear"
            self.origin = DEFAULT_ORIGIN.copy()
        self.nav_status = "Geocoding + routing via Google Maps..."
        origin_request = self.origin.copy()
        if refresh:
            origin_request = {"lat": self.lat, "lng": self.lng, "label": self.origin.get("label", "Current position")}
        self.route_worker.request_resolve(
            origin_request,
            self.destination,
            step_index=int((self.route_context or {}).get("step_index", 0)),
        )
        self.force_pulse = True

    def _stop_navigation(self) -> None:
        self.navigation_active = False
        self.route_context = None
        self.route_visualization = None
        self.map_panel.set_static_map(None)
        self.nav_status = "Navigation stopped"
        self.scenario_label = "Navigation off - press D to restart"
        self.force_pulse = True

    def _apply_route_result(self, result: dict[str, Any]) -> None:
        if not result.get("ok"):
            self.nav_status = f"Google route failed: {result.get('error', 'unknown')[:80]}"
            return

        data = result["data"]
        self.route_context = data.get("route_context")
        self.route_visualization = data.get("route_visualization")
        resolved_dest = data.get("destination") or self.destination
        resolved_origin = data.get("origin") or {}
        self.destination = resolved_dest
        if resolved_origin.get("lat") is not None and resolved_origin.get("lng") is not None:
            self.lat = float(resolved_origin["lat"])
            self.lng = float(resolved_origin["lng"])
            self.origin = resolved_origin

        static_url = str((self.route_visualization or {}).get("static_map_url", ""))
        if static_url:
            tile = fetch_static_map_surface(
                static_url,
                self.map_panel.width,
                self.map_panel.height,
            )
            self.map_panel.set_static_map(tile, cache_key=static_url[:120])
            if tile is None:
                self.nav_status = "Route OK but Static Map failed - enable Maps Static API"
        else:
            self.map_panel.set_static_map(None)

        instruction = (self.route_context or {}).get("instruction", "Route ready")
        distance_m = (self.route_context or {}).get("distance_m", 0)
        source = (self.route_context or {}).get("source", "google_directions")
        origin_label = self.origin.get("label", "Nazimabad")
        self.nav_status = (
            f"Google OK | {origin_label} -> {resolved_dest.get('label', 'Saddar')} | "
            f"{distance_m} m | {instruction[:45]}"
        )
        self.scenario_label = f"Sim GPS @ {self.lat:.4f}, {self.lng:.4f}"
        self.force_pulse = True

    def _poll_route_results(self) -> None:
        latest = self.route_worker.latest_result()
        if latest:
            self._apply_route_result(latest)

    def _read_camera_frame(self):
        if not self.use_camera or not self.cap.isOpened():
            return self._placeholder_frame()
        ok, frame = self.cap.read()
        if not ok:
            return self._placeholder_frame()
        return cv2.resize(frame, (self.width, self.height))

    def _placeholder_frame(self):
        frame = np.full((self.height, self.width, 3), (40, 30, 30), dtype=np.uint8)
        cv2.putText(
            frame,
            self.scenario_label[:55],
            (40, self.height // 2 - 20),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (220, 200, 200),
            2,
            cv2.LINE_AA,
        )
        if self.navigation_active:
            cv2.putText(
                frame,
                self.nav_status[:60],
                (40, self.height // 2 + 20),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (120, 200, 255),
                1,
                cv2.LINE_AA,
            )
        return frame

    def _build_payload(self, frame_bgr) -> dict[str, Any]:
        if self.use_camera:
            frame_data = frame_to_base64(frame_bgr)
        else:
            frame_data = self.fixture_token

        payload: dict[str, Any] = {
            "speed": self.speed,
            "coordinates": {"lat": self.lat, "lng": self.lng},
            "frame_data": frame_data,
            "session_id": "hud-sim-001",
            "rider_id": "sim-rider",
        }

        if self.navigation_active:
            payload["destination"] = self.destination
            if self.route_context:
                payload["route_context"] = self.route_context
                payload["route_step_index"] = self.route_context.get("step_index", 0)
            if self.route_visualization:
                payload["route_visualization"] = self.route_visualization

        return payload

    def _maybe_send_pulse(self, frame_bgr) -> None:
        now = time.monotonic()
        if self.force_pulse or (now - self.last_pulse) >= self.pulse_interval:
            self.ws.enqueue_pulse(self._build_payload(frame_bgr))
            self.last_pulse = now
            self.force_pulse = False

    def _handle_keys(self) -> bool:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    return False
                if event.key == pygame.K_d:
                    self._start_google_navigation()
                if event.key == pygame.K_r:
                    if self.navigation_active:
                        self._start_google_navigation(refresh=True)
                if event.key == pygame.K_n:
                    self._stop_navigation()
                if event.key == pygame.K_c:
                    self.use_camera = not self.use_camera
                    if self.use_camera and not self.cap.isOpened():
                        self.cap = cv2.VideoCapture(0)
                    self.scenario_label = "Live camera" if self.use_camera else self.fixture_token
                if event.key in SCENARIOS:
                    token, label = SCENARIOS[event.key]
                    self.use_camera = False
                    self.fixture_token = token
                    self.scenario_label = label
                if event.key == pygame.K_SPACE:
                    self.force_pulse = True
                step = 0.0004 if self.navigation_active else 0.0003
                if event.key == pygame.K_UP:
                    self.lat += step
                if event.key == pygame.K_DOWN:
                    self.lat -= step
                if event.key == pygame.K_LEFT:
                    self.lng -= step
                if event.key == pygame.K_RIGHT:
                    self.lng += step
                if event.key in (pygame.K_EQUALS, pygame.K_PLUS):
                    self.speed = min(60.0, self.speed + 2)
                if event.key == pygame.K_MINUS:
                    self.speed = max(0.0, self.speed - 2)
        return True

    def _blit_camera(self, frame_bgr) -> None:
        rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
        surf = pygame.surfarray.make_surface(rgb.swapaxes(0, 1))
        self.screen.blit(surf, (0, 0))

    def _draw_hud(self) -> None:
        resp = self.last_response
        threat = str(resp.get("threat_level", "NORMAL")).upper()
        ring_color = THREAT_RING.get(threat, (100, 100, 100))
        cx, cy = self.width // 2, self.height // 2 + 40
        pygame.draw.circle(self.screen, ring_color, (cx, cy), 72, 6)
        pygame.draw.circle(self.screen, (*ring_color, 40), (cx, cy), 88, 2)

        threat_surf = self.font.render(f"THREAT: {threat}", True, ring_color)
        self.screen.blit(threat_surf, (24, 24))

        hud_mode = str(resp.get("hud_mode", "idle"))
        self.screen.blit(self.font.render(f"HUD: {hud_mode}", True, (180, 180, 200)), (24, 48))

        conn = "CONNECTED" if self.ws.connected else "DISCONNECTED"
        conn_color = (80, 220, 120) if self.ws.connected else (255, 80, 80)
        self.screen.blit(self.font.render(conn, True, conn_color), (24, 72))
        if self.ws.last_error and not self.ws.connected:
            err = self.small_font.render(self.ws.last_error[:70], True, (255, 120, 120))
            self.screen.blit(err, (24, 94))

        nav = resp.get("navigation") or {}
        if self.navigation_active and not nav and self.route_context:
            nav = {
                "arrow": self.route_context.get("arrow", "STRAIGHT"),
                "instruction": self.route_context.get("instruction", ""),
                "distance_m": self.route_context.get("distance_m", 0),
            }
        self.nav_arrow.draw(self.screen, nav)

        pinned = list(resp.get("pinned_pois") or [])
        route_viz = resp.get("route_visualization") or self.route_visualization
        self.map_panel.draw(
            self.screen,
            (self.width - self.map_panel.width - 16, self.height - self.map_panel.height - 16),
            self.lat,
            self.lng,
            pinned,
            self.zones if not self.navigation_active else [],
            route_viz,
        )

        ctx = str(resp.get("enriched_context") or "")
        dest = resp.get("destination") or self.destination or {}
        dest_label = dest.get("label", "-")
        nav_source = nav.get("source", "-")
        origin_label = self.origin.get("label", "-")
        lines = [
            f"Speed: {self.speed:.0f} km/h | {'NAV ON' if self.navigation_active else 'NAV OFF'} | Simulated GPS (PC has no GPS)",
            f"Source: {origin_label} ({self.lat:.4f}, {self.lng:.4f})",
            f"Destination: {dest_label}",
            f"Nav source: {nav_source}",
            f"Google: {self.nav_status[:90]}",
            f"Context: {ctx[:75]}",
        ]
        ui_cmds = resp.get("ui_commands") or []
        if ui_cmds:
            lines.append(f"UI: {', '.join(str(c) for c in ui_cmds[:4])}")

        y = self.height - 108
        for line in lines:
            bg = self.small_font.render(line, True, (0, 0, 0))
            fg = self.small_font.render(line, True, (220, 220, 230))
            self.screen.blit(bg, (25, y + 1))
            self.screen.blit(fg, (24, y))
            y += 16

        help_text = "D Google nav | R refresh route | N stop | 1-5 hazards | Arrows move | SPACE pulse"
        help_surf = self.small_font.render(help_text, True, (140, 140, 160))
        self.screen.blit(help_surf, (24, self.height - 22))

    def run(self) -> None:
        running = True
        while running:
            running = self._handle_keys()
            self._poll_route_results()
            frame = self._read_camera_frame()
            self._maybe_send_pulse(frame)
            latest = self.ws.latest_response()
            if latest:
                self.last_response = latest
                if latest.get("route_visualization"):
                    self.route_visualization = latest["route_visualization"]
                if latest.get("destination"):
                    self.destination = latest["destination"]

            self._blit_camera(frame)
            self._draw_hud()
            pygame.display.flip()
            self.clock.tick(30)

        self.ws.stop()
        self.route_worker.stop()
        if self.cap.isOpened():
            self.cap.release()
        pygame.quit()


def main() -> None:
    parser = argparse.ArgumentParser(description="ArgusX Pygame + OpenCV HUD simulator")
    parser.add_argument("--ws", default=DEFAULT_WS, help="WebSocket URL (default: %(default)s)")
    parser.add_argument("--api", default=None, help="REST API base (default: derived from --ws)")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=720)
    args = parser.parse_args()

    api_base = args.api or ws_to_api_base(args.ws)
    sim = ArgusXHudSimulator(args.ws, api_base, args.width, args.height)
    sim.run()


if __name__ == "__main__":
    main()
