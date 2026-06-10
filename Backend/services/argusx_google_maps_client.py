"""Google Maps Geocoding + Directions client for turn-by-turn route context.

Used when the mobile client sends a ``destination`` without a pre-computed
``route_context`` (Flutter can also compute the route locally and skip this).
"""

from __future__ import annotations

import logging
import re
from typing import Any

import httpx

from config.argusx_settings import ArgusXSettings
from graph.argusx_state import Coordinates, Destination, NavArrow, RouteContext, RouteVisualization

logger = logging.getLogger("argusx.services.google_maps")

_GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"
_DIRECTIONS_URL = "https://maps.googleapis.com/maps/api/directions/json"
_STATIC_MAP_URL = "https://maps.googleapis.com/maps/api/staticmap"


class ArgusXGoogleMapsClient:
    """Resolves addresses and driving routes via the Google Maps Platform APIs."""

    def __init__(self, settings: ArgusXSettings) -> None:
        self._settings = settings
        self._client: httpx.AsyncClient | None = None

    @property
    def is_configured(self) -> bool:
        return bool(self._settings.google_maps_api_key.strip())

    async def startup(self) -> None:
        if self._client is None:
            self._client = httpx.AsyncClient(timeout=self._settings.google_maps_timeout_seconds)

    async def shutdown(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    async def health_check(self) -> dict[str, Any]:
        return {
            "configured": self.is_configured,
            "enabled": self._settings.google_maps_enabled,
        }

    async def geocode(self, query: str) -> Destination | None:
        """Resolve a place label (e.g. ``Saddar, Karachi``) to coordinates."""
        if not self.is_configured or not self._settings.google_maps_enabled:
            return None

        client = self._require_client()
        response = await client.get(
            _GEOCODE_URL,
            params={"address": query, "key": self._settings.google_maps_api_key},
        )
        response.raise_for_status()
        payload = response.json()
        if payload.get("status") != "OK" or not payload.get("results"):
            logger.warning("Geocode failed for %r: %s", query, payload.get("status"))
            return None

        result = payload["results"][0]
        location = result["geometry"]["location"]
        return {
            "lat": float(location["lat"]),
            "lng": float(location["lng"]),
            "label": result.get("formatted_address", query),
        }

    async def resolve_route(
        self,
        origin: Coordinates | Destination,
        destination: Destination,
        *,
        step_index: int = 0,
    ) -> tuple[RouteContext, RouteVisualization, Destination] | None:
        """Fetch driving directions and extract the active maneuver + route polyline."""
        resolved_origin = None
        dest = None

        if self.is_configured and self._settings.google_maps_enabled:
            try:
                resolved_origin = await self._ensure_point_coords(origin, fallback_label="Origin")
            except Exception as e:
                logger.warning("Failed to resolve origin coords: %s", e)
            try:
                dest = await self._ensure_destination_coords(destination)
            except Exception as e:
                logger.warning("Failed to resolve destination coords: %s", e)

        # Coordinate fallbacks if geocoding failed or disabled
        if resolved_origin is None:
            resolved_origin = {
                "lat": float(origin.get("lat") or 24.8607),
                "lng": float(origin.get("lng") or 67.0011),
                "label": origin.get("label") or "Origin",
            }
        if dest is None:
            dest = {
                "lat": float(destination.get("lat") or 24.8687),
                "lng": float(destination.get("lng") or 67.0081),
                "label": destination.get("label") or "Destination",
            }

        o_lat = float(resolved_origin["lat"])
        o_lng = float(resolved_origin["lng"])
        d_lat = float(dest["lat"])
        d_lng = float(dest["lng"])

        # Try Google Directions
        if self.is_configured and self._settings.google_maps_enabled:
            try:
                client = self._require_client()
                response = await client.get(
                    _DIRECTIONS_URL,
                    params={
                        "origin": f"{o_lat},{o_lng}",
                        "destination": f"{d_lat},{d_lng}",
                        "mode": "driving",
                        "key": self._settings.google_maps_api_key,
                    },
                )
                response.raise_for_status()
                payload = response.json()
                if payload.get("status") == "OK" and payload.get("routes"):
                    route = payload["routes"][0]
                    leg = route["legs"][0]
                    steps = leg.get("steps", [])
                    if steps:
                        idx = max(0, min(step_index, len(steps) - 1))
                        step = steps[idx]
                        maneuver = str(step.get("maneuver", "straight"))
                        html_instruction = str(step.get("html_instructions", ""))
                        plain_instruction = _strip_html(html_instruction) or "Continue on route"

                        route_context: RouteContext = {
                            "arrow": _maneuver_to_arrow(maneuver, plain_instruction),
                            "instruction": plain_instruction,
                            "distance_m": int(step.get("distance", {}).get("value", 0)),
                            "duration_s": int(step.get("duration", {}).get("value", 0)),
                            "step_index": idx,
                            "total_steps": len(steps),
                            "maneuver": maneuver,
                            "source": "google_directions",
                        }

                        polyline = route.get("overview_polyline", {}).get("points", "")
                        route_visualization: RouteVisualization = {
                            "polyline": polyline,
                            "origin": resolved_origin,
                            "destination": dest,
                            "distance_remaining_m": int(leg.get("distance", {}).get("value", 0)),
                            "leg_distance_m": int(leg.get("distance", {}).get("value", 0)),
                            "step_index": idx,
                            "total_steps": len(steps),
                            "source": "google_directions",
                            "static_map_url": self.build_static_map_url(
                                resolved_origin,
                                dest,
                                polyline,
                            ),
                        }
                        return route_context, route_visualization, resolved_origin
                else:
                    logger.warning("Directions API status not OK: %s", payload.get("status"))
            except Exception as e:
                logger.warning("Google Maps Directions call failed: %s", e)

        # Fallback mock route with dynamic, real static map URL (if configured) or placeholder
        mock_dest_label = dest.get("label", "Destination")
        mock_polyline = "a~~FzsgvOq@n@`@p@`@`@`@"
        mock_route_ctx: RouteContext = {
            "arrow": "RIGHT" if step_index % 2 == 0 else "LEFT",
            "instruction": f"Prepare to turn towards {mock_dest_label} (Simulation Path)",
            "distance_m": 850 - (step_index * 150),
            "duration_s": 120,
            "step_index": step_index,
            "total_steps": 4,
            "maneuver": "turn-right" if step_index % 2 == 0 else "turn-left",
            "source": "simulation_fallback",
        }
        
        static_map_url = ""
        if self.is_configured:
            try:
                static_map_url = self.build_static_map_url(resolved_origin, dest, mock_polyline)
            except Exception:
                pass

        mock_route_viz: RouteVisualization = {
            "polyline": mock_polyline,
            "origin": resolved_origin,
            "destination": dest,
            "distance_remaining_m": 850 - (step_index * 150),
            "leg_distance_m": 850,
            "step_index": step_index,
            "total_steps": 4,
            "source": "simulation_fallback",
            "static_map_url": static_map_url,
        }
        return mock_route_ctx, mock_route_viz, resolved_origin

    def build_static_map_url(
        self,
        origin: Destination,
        destination: Destination,
        polyline: str,
        *,
        width: int = 340,
        height: int = 200,
    ) -> str:
        """Build a Google Static Maps URL showing road tiles, route path, and pins."""
        if not self.is_configured or not polyline:
            return ""

        o_lat = origin.get("lat")
        o_lng = origin.get("lng")
        d_lat = destination.get("lat")
        d_lng = destination.get("lng")
        if o_lat is None or o_lng is None or d_lat is None or d_lng is None:
            return ""

        from urllib.parse import quote

        parts = [
            f"size={width}x{height}",
            "maptype=roadmap",
            "scale=2",
            f"path={quote(f'color:0x4285F4ff|weight:5|enc:{polyline}', safe='')}",
            f"markers={quote(f'color:green|label:S|{o_lat},{o_lng}', safe='')}",
            f"markers={quote(f'color:red|label:D|{d_lat},{d_lng}', safe='')}",
            f"key={quote(self._settings.google_maps_api_key, safe='')}",
        ]
        return f"{_STATIC_MAP_URL}?{'&'.join(parts)}"

    async def _ensure_point_coords(
        self,
        point: Coordinates | Destination,
        *,
        fallback_label: str,
    ) -> Destination | None:
        lat = point.get("lat")
        lng = point.get("lng")
        label = str(point.get("label", "")).strip()

        if lat is not None and lng is not None and float(lat) != 0.0 and float(lng) != 0.0:
            return {
                "lat": float(lat),
                "lng": float(lng),
                "label": label or fallback_label,
            }
        if label:
            geocoded = await self.geocode(label)
            if geocoded:
                return geocoded
        return None

    async def _ensure_destination_coords(self, destination: Destination) -> Destination | None:
        return await self._ensure_point_coords(destination, fallback_label="Destination")

    async def fetch_static_map(self, url: str) -> tuple[bytes, str] | None:
        """Fetch a Google Static Map image server-side.

        Returns ``(image_bytes, content_type)`` so the API can stream the image
        from its own (CORS-enabled) origin instead of redirecting the browser to
        ``maps.googleapis.com`` — Google's image responses carry no CORS headers,
        which breaks Flutter Web's CanvasKit renderer.
        """
        if not url:
            return None
        client = self._require_client()
        try:
            resp = await client.get(url)
            resp.raise_for_status()
        except httpx.HTTPError as exc:
            logger.warning("Static map fetch failed: %s", exc)
            return None
        content_type = resp.headers.get("content-type", "image/png")
        return resp.content, content_type

    def _require_client(self) -> httpx.AsyncClient:
        if self._client is None:
            raise RuntimeError("ArgusXGoogleMapsClient is not started.")
        return self._client


def _strip_html(value: str) -> str:
    cleaned = re.sub(r"<[^>]+>", " ", value)
    return re.sub(r"\s+", " ", cleaned).strip()


def _maneuver_to_arrow(maneuver: str, instruction: str) -> NavArrow:
    m = maneuver.lower()
    if "u-turn" in m or "uturn" in m:
        return "U_TURN"
    if "turn-left" in m or m.endswith("-left") or m == "left":
        return "LEFT"
    if "turn-right" in m or m.endswith("-right") or m == "right":
        return "RIGHT"
    if "roundabout-left" in m:
        return "LEFT"
    if "roundabout-right" in m:
        return "RIGHT"
    # Ignore prose in instructions ("on the right") — only use maneuver token.
    if m in {"merge", "fork-left"}:
        return "LEFT"
    if m in {"fork-right"}:
        return "RIGHT"
    return "STRAIGHT"
