"""Supabase persistence for rides, fleet positions, and safety events.

Called from the Safety Pulse WebSocket path using the service-role key.
All writes are best-effort and must never block the realtime HUD loop.
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from typing import Any, Optional

from database.argusx_database import ArgusXDatabase

logger = logging.getLogger("argusx.persistence")

_ANONYMOUS_RIDER_IDS = frozenset({"anonymous", "operator-01", "demo-rider", ""})
_VALID_PLATFORMS = frozenset({"flutter_android", "flutter_ios", "flutter_web", "unknown"})


def _is_valid_rider_id(rider_id: str | None) -> bool:
    if not rider_id or rider_id in _ANONYMOUS_RIDER_IDS:
        return False
    try:
        uuid.UUID(str(rider_id))
        return True
    except ValueError:
        return False


def _num(value: Any) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _point_coords(data: dict[str, Any] | None) -> tuple[float | None, float | None]:
    if not data:
        return None, None
    return _num(data.get("lat")), _num(data.get("lng"))


class ArgusXPersistence:
    """Thin async wrapper around Supabase RPC calls."""

    def __init__(self, database: ArgusXDatabase) -> None:
        self._database = database

    @property
    def enabled(self) -> bool:
        return self._database.is_connected

    async def on_pulse(
        self,
        payload: dict[str, Any],
        result: dict[str, Any],
    ) -> None:
        if not self.enabled:
            return

        rider_id = str(payload.get("rider_id", ""))
        if not _is_valid_rider_id(rider_id):
            return

        session_id = str(payload.get("session_id", "ws-session"))
        coordinates = payload.get("coordinates") or {}
        lat = _num(coordinates.get("lat"))
        lng = _num(coordinates.get("lng"))
        if lat is None or lng is None:
            return

        destination = payload.get("destination") or {}
        route_viz = payload.get("route_visualization") or result.get("route_visualization") or {}
        dest_label = destination.get("label")
        origin = route_viz.get("origin") or {}
        dest_point = route_viz.get("destination") or destination
        origin_lat, origin_lng = _point_coords(origin)
        dest_lat, dest_lng = _point_coords(dest_point)

        platform_raw = str(payload.get("platform", "unknown"))
        platform = platform_raw if platform_raw in _VALID_PLATFORMS else "unknown"
        device_label = str(payload.get("device_label", "ArgusX Device"))

        await asyncio.to_thread(
            self._sync_pulse,
            rider_id=rider_id,
            session_id=session_id,
            lat=lat,
            lng=lng,
            speed=float(payload.get("speed", 0.0)),
            threat_level=str(result.get("threat_level", "NORMAL")).upper(),
            hud_mode=str(result.get("hud_mode", "")),
            destination_label=dest_label,
            origin_label=origin.get("label"),
            origin_lat=origin_lat,
            origin_lng=origin_lng,
            destination_lat=dest_lat,
            destination_lng=dest_lng,
            route_polyline=route_viz.get("polyline"),
            distance_m=route_viz.get("leg_distance_m") or route_viz.get("distance_remaining_m"),
            platform=platform,
            device_label=device_label,
        )

    async def on_disconnect(self, rider_id: str | None, session_id: str | None) -> None:
        if not self.enabled:
            return
        if session_id:
            await asyncio.to_thread(self._sync_complete_ride, session_id)
        elif rider_id and _is_valid_rider_id(rider_id):
            await asyncio.to_thread(self._sync_mark_offline, rider_id)

    async def on_safety_event(
        self,
        event: dict[str, Any],
        rider_id: str,
        session_id: str,
    ) -> None:
        if not self.enabled or not _is_valid_rider_id(rider_id):
            return

        coords = event.get("coordinates") or {}
        await asyncio.to_thread(
            self._sync_safety_event,
            event_id=str(event.get("event_id", "")),
            rider_id=rider_id,
            session_id=session_id,
            threat_level=str(event.get("threat_level", "WARNING")).upper(),
            lat=_num(coords.get("lat")),
            lng=_num(coords.get("lng")),
            speed_kmh=_num(event.get("speed")),
            hazards=event.get("hazards") or [],
            enriched_context=event.get("enriched_context"),
            ui_commands=event.get("ui_commands") or [],
        )

    def _sync_pulse(self, **kwargs: Any) -> None:
        try:
            client = self._database.client
            device_id = client.rpc(
                "ensure_device",
                {
                    "p_user_id": kwargs["rider_id"],
                    "p_device_label": kwargs["device_label"],
                    "p_platform": kwargs["platform"],
                },
            ).execute()

            device_uuid = None
            if device_id.data is not None:
                device_uuid = device_id.data

            ride_id = client.rpc(
                "ensure_active_ride",
                {
                    "p_user_id": kwargs["rider_id"],
                    "p_session_id": kwargs["session_id"],
                    "p_device_id": device_uuid,
                    "p_origin_label": kwargs.get("origin_label"),
                    "p_origin_lat": kwargs.get("origin_lat"),
                    "p_origin_lng": kwargs.get("origin_lng"),
                    "p_destination_label": kwargs.get("destination_label"),
                    "p_destination_lat": kwargs.get("destination_lat"),
                    "p_destination_lng": kwargs.get("destination_lng"),
                    "p_route_polyline": kwargs.get("route_polyline"),
                    "p_distance_m": kwargs.get("distance_m"),
                },
            ).execute()

            ride_uuid = ride_id.data

            client.rpc(
                "upsert_fleet_position",
                {
                    "p_user_id": kwargs["rider_id"],
                    "p_ride_id": ride_uuid,
                    "p_session_id": kwargs["session_id"],
                    "p_device_id": device_uuid,
                    "p_lat": kwargs["lat"],
                    "p_lng": kwargs["lng"],
                    "p_speed_kmh": kwargs["speed"],
                    "p_threat_level": kwargs["threat_level"],
                    "p_hud_mode": kwargs.get("hud_mode"),
                    "p_destination_label": kwargs.get("destination_label"),
                },
            ).execute()

            client.rpc(
                "update_ride_pulse",
                {
                    "p_session_id": kwargs["session_id"],
                    "p_speed_kmh": kwargs["speed"],
                    "p_threat_level": kwargs["threat_level"],
                },
            ).execute()
        except Exception as exc:
            logger.warning("Pulse persistence failed: %s", exc)

    def _sync_complete_ride(self, session_id: str) -> None:
        try:
            self._database.client.rpc(
                "complete_ride_session",
                {"p_session_id": session_id},
            ).execute()
        except Exception as exc:
            logger.warning("Complete ride persistence failed: %s", exc)

    def _sync_mark_offline(self, rider_id: str) -> None:
        try:
            self._database.client.rpc(
                "mark_rider_offline",
                {"p_user_id": rider_id},
            ).execute()
        except Exception as exc:
            logger.warning("Mark offline persistence failed: %s", exc)

    def _sync_safety_event(self, **kwargs: Any) -> None:
        event_id = kwargs.get("event_id")
        if not event_id:
            return
        try:
            self._database.client.rpc(
                "record_safety_event",
                {
                    "p_event_id": event_id,
                    "p_user_id": kwargs["rider_id"],
                    "p_session_id": kwargs["session_id"],
                    "p_threat_level": kwargs["threat_level"],
                    "p_lat": kwargs.get("lat"),
                    "p_lng": kwargs.get("lng"),
                    "p_speed_kmh": kwargs.get("speed_kmh"),
                    "p_hazards": kwargs.get("hazards"),
                    "p_enriched_context": kwargs.get("enriched_context"),
                    "p_ui_commands": kwargs.get("ui_commands"),
                },
            ).execute()
        except Exception as exc:
            logger.warning("Safety event persistence failed: %s", exc)
