"""Async HTTP client for the Java compliance microservice.

Dispatches threat events and menu-config queries as non-blocking fire-and-forget
POST requests so the Safety Pulse WebSocket path is never blocked.
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Optional

import httpx

from config.argusx_settings import ArgusXSettings
from database.argusx_persistence import ArgusXPersistence
from graph.argusx_state import ArgusXState

logger = logging.getLogger("argusx.compliance_client")

COMPLIANCE_THREAT_PATH = "/api/compliance/threat-event"
COMPLIANCE_MENU_PATH = "/api/compliance/menu-config"
COMPLIANCE_HEALTH_PATH = "/api/compliance/health"


class ArgusXComplianceClient:
    """Fire-and-forget egress client for the Java compliance layer."""

    def __init__(
        self,
        settings: ArgusXSettings,
        persistence: ArgusXPersistence | None = None,
    ) -> None:
        self._settings = settings
        self._persistence = persistence
        self._client: Optional[httpx.AsyncClient] = None
        self._reachable: bool = False

    @property
    def is_enabled(self) -> bool:
        return self._settings.compliance_enabled

    @property
    def is_reachable(self) -> bool:
        return self._reachable

    @property
    def base_url(self) -> str:
        return self._settings.compliance_service_url.rstrip("/")

    async def startup(self) -> None:
        if not self.is_enabled:
            logger.info("Compliance client disabled (ARGUSX_COMPLIANCE_ENABLED=false).")
            return

        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=httpx.Timeout(self._settings.compliance_timeout_seconds),
        )
        self._reachable = await self.ping()
        if self._reachable:
            logger.info("Compliance service reachable at %s", self.base_url)
        else:
            logger.warning(
                "Compliance service not reachable at %s — events will be skipped.",
                self.base_url,
            )

    async def shutdown(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None
        self._reachable = False

    async def ping(self) -> bool:
        if not self.is_enabled or self._client is None:
            return False
        try:
            response = await self._client.get(COMPLIANCE_HEALTH_PATH)
            self._reachable = response.status_code == 200
            return self._reachable
        except httpx.HTTPError:
            self._reachable = False
            return False

    def dispatch_threat_event(
        self,
        state: ArgusXState,
        *,
        session_id: str = "sim-session",
        rider_id: str = "test-rider",
    ) -> None:
        """Schedule a non-blocking threat-event POST. Returns immediately."""
        if not self.is_enabled:
            return

        threat_level = state.get("threat_level", "NORMAL")
        if threat_level not in {"WARNING", "CRITICAL"}:
            return

        payload = self._build_threat_payload(state, session_id=session_id, rider_id=rider_id)
        asyncio.create_task(self._post_threat_event(payload))
        if self._persistence is not None:
            asyncio.create_task(
                self._persistence.on_safety_event(payload, rider_id, session_id)
            )

    async def post_threat_event(
        self,
        state: ArgusXState,
        *,
        session_id: str = "sim-session",
        rider_id: str = "test-rider",
    ) -> dict[str, Any]:
        """Awaitable threat-event POST — used by test scripts."""
        payload = self._build_threat_payload(state, session_id=session_id, rider_id=rider_id)
        return await self._post_threat_event(payload)

    async def fetch_menu_config(self, rider_id: str = "test-rider") -> dict[str, Any]:
        if not self.is_enabled:
            return {"status": "disabled"}
        if self._client is None:
            await self.startup()
        if self._client is None:
            return {"status": "unavailable"}

        payload = {"rider_id": rider_id, "request_type": "HUD_MENU_CONFIG"}
        try:
            response = await self._client.post(COMPLIANCE_MENU_PATH, json=payload)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as exc:
            logger.warning("Menu config request failed: %s", exc)
            return {"status": "error", "detail": str(exc)}

    def _build_threat_payload(
        self,
        state: ArgusXState,
        *,
        session_id: str,
        rider_id: str,
    ) -> dict[str, Any]:
        coordinates = state.get("coordinates") or {}
        return {
            "event_id": str(uuid.uuid4()),
            "session_id": session_id,
            "rider_id": rider_id,
            "threat_level": state.get("threat_level", "NORMAL"),
            "hazards": state.get("hazards", []),
            "coordinates": {
                "lat": coordinates.get("lat"),
                "lng": coordinates.get("lng"),
            },
            "speed": state.get("speed", 0.0),
            "enriched_context": state.get("enriched_context", ""),
            "ui_commands": state.get("ui_commands", []),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

    async def _post_threat_event(self, payload: dict[str, Any]) -> dict[str, Any]:
        if self._client is None:
            await self.startup()
        if self._client is None:
            return {"status": "unavailable"}

        try:
            response = await self._client.post(COMPLIANCE_THREAT_PATH, json=payload)
            response.raise_for_status()
            logger.info(
                "Compliance event dispatched: threat=%s event_id=%s",
                payload.get("threat_level"),
                payload.get("event_id"),
            )
            return response.json()
        except httpx.HTTPError as exc:
            logger.warning("Compliance dispatch failed (non-blocking): %s", exc)
            self._reachable = False
            return {"status": "error", "detail": str(exc)}

    async def health_check(self) -> dict[str, Any]:
        return {
            "enabled": self.is_enabled,
            "reachable": self._reachable,
            "base_url": self.base_url if self.is_enabled else None,
        }
