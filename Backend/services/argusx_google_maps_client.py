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
        if not self.is_configured or not self._settings.google_maps_enabled:
            return None

        resolved_origin = await self._ensure_point_coords(origin, fallback_label="Origin")
        dest = await self._ensure_destination_coords(destination)
        if resolved_origin is None or dest is None:
            return None

        o_lat = float(resolved_origin["lat"])
        o_lng = float(resolved_origin["lng"])
        d_lat = float(dest["lat"])
        d_lng = float(dest["lng"])

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
        if payload.get("status") != "OK" or not payload.get("routes"):
            logger.warning("Directions failed: %s", payload.get("status"))
            return None

        route = payload["routes"][0]
        leg = route["legs"][0]
        steps = leg.get("steps", [])
        if not steps:
            return None

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
