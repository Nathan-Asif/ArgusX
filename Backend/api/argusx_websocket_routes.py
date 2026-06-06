"""Real-time Safety Pulse WebSocket routes.

Holds a reference to the compiled agent graph and pushes each inbound telemetry
frame through it, streaming the resulting action command back to the client.
This is the bi-directional channel the Flutter HUD connects to.
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from graph.argusx_agent_graph import ArgusXAgentGraph
from graph.argusx_state import ArgusXState

logger = logging.getLogger("argusx.api.websocket")


class ArgusXWebSocketRoutes:
    """Builds the ``/ws/pulse`` router bound to the agent graph."""

    def __init__(self, agent_graph: ArgusXAgentGraph) -> None:
        self._agent_graph = agent_graph
        self.router = APIRouter(tags=["pulse"])
        self._register()

    def _register(self) -> None:
        @self.router.websocket("/ws/pulse")
        async def pulse(websocket: WebSocket) -> None:
            await websocket.accept()
            logger.info("Safety Pulse client connected.")
            try:
                while True:
                    payload = await websocket.receive_json()
                    state: ArgusXState = {
                        "speed": payload.get("speed", 0.0),
                        "coordinates": payload.get("coordinates", {}),
                        "frame_data": payload.get("frame_data", ""),
                    }
                    result = await self._agent_graph.ainvoke(state)
                    await websocket.send_json(
                        {
                            "threat_level": result.get("threat_level", "NORMAL"),
                            "ui_commands": result.get("ui_commands", []),
                            "enriched_context": result.get("enriched_context", ""),
                        }
                    )
            except WebSocketDisconnect:
                logger.info("Safety Pulse client disconnected.")
