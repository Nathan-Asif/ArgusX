"""Real-time Safety Pulse WebSocket routes.

Holds a reference to the compiled agent graph and pushes each inbound telemetry
frame through it, streaming the resulting action command back to the client.
This is the bi-directional channel the Flutter HUD connects to.
"""

from __future__ import annotations

import asyncio
import logging
from typing import Any

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from database.argusx_persistence import ArgusXPersistence
from graph.argusx_agent_graph import ArgusXAgentGraph
from graph.argusx_state import ArgusXState, Destination, RouteContext, RouteVisualization
from services.argusx_compliance_client import ArgusXComplianceClient
from services.argusx_google_maps_client import ArgusXGoogleMapsClient

logger = logging.getLogger("argusx.api.websocket")


class ArgusXWebSocketRoutes:
    """Builds the ``/ws/pulse`` router bound to the agent graph."""

    def __init__(
        self,
        agent_graph: ArgusXAgentGraph,
        compliance_client: ArgusXComplianceClient,
        maps_client: ArgusXGoogleMapsClient,
        persistence: ArgusXPersistence | None = None,
    ) -> None:
        self._agent_graph = agent_graph
        self._compliance_client = compliance_client
        self._maps_client = maps_client
        self._persistence = persistence
        self.router = APIRouter(tags=["pulse"])
        self._register()

    async def _resolve_route_context(
        self,
        payload: dict[str, Any],
    ) -> tuple[Destination | None, RouteContext | None, RouteVisualization | None]:
        destination: Destination | None = payload.get("destination")
        route_context: RouteContext | None = payload.get("route_context")
        route_visualization: RouteVisualization | None = payload.get("route_visualization")

        if route_context:
            return destination, route_context, route_visualization

        if not destination:
            return None, None, None

        coordinates = payload.get("coordinates") or {}
        if not coordinates.get("lat") or not coordinates.get("lng"):
            return destination, None, None

        step_index = int(payload.get("route_step_index", 0))
        resolved = await self._maps_client.resolve_route(
            coordinates,
            destination,
            step_index=step_index,
        )
        if resolved is None:
            logger.info("Route not resolved server-side; awaiting client route_context or API key.")
            return destination, None, None

        ctx, viz, _resolved_origin = resolved
        return viz.get("destination") or destination, ctx, viz

    def _register(self) -> None:
        @self.router.websocket("/ws/pulse")
        async def pulse(websocket: WebSocket) -> None:
            await websocket.accept()
            logger.info("Safety Pulse client connected.")
            session_id: str | None = None
            rider_id: str | None = None
            try:
                while True:
                    payload = await websocket.receive_json()
                    session_id = str(payload.get("session_id", "ws-session"))
                    rider_id = str(payload.get("rider_id", "anonymous"))
                    destination, route_context, route_visualization = await self._resolve_route_context(
                        payload
                    )

                    state: ArgusXState = {
                        "speed": payload.get("speed", 0.0),
                        "coordinates": payload.get("coordinates", {}),
                        "frame_data": payload.get("frame_data", ""),
                        "destination": destination,
                        "route_context": route_context,
                        "route_visualization": route_visualization,
                    }
                    result = await self._agent_graph.ainvoke(state)
                    self._compliance_client.dispatch_threat_event(
                        result,
                        session_id=payload.get("session_id", "ws-session"),
                        rider_id=payload.get("rider_id", "anonymous"),
                    )
                    response_payload = {
                        "threat_level": result.get("threat_level", "NORMAL"),
                        "ui_commands": result.get("ui_commands", []),
                        "enriched_context": result.get("enriched_context", ""),
                        "hud_mode": result.get("hud_mode", "Sentry_Active"),
                        "navigation": result.get("navigation", {}),
                        "pinned_pois": result.get("pinned_pois", []),
                        "hazards": result.get("hazards", []),
                        "destination": destination,
                        "route_visualization": route_visualization or {},
                    }
                    await websocket.send_json(response_payload)

                    if self._persistence is not None:
                        asyncio.create_task(
                            self._persistence.on_pulse(payload, response_payload)
                        )
            except WebSocketDisconnect:
                logger.info("Safety Pulse client disconnected.")
                if self._persistence is not None:
                    asyncio.create_task(
                        self._persistence.on_disconnect(rider_id, session_id)
                    )
