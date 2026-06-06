"""Routing engine node — Node 3 of the ArgusX agent graph.

Computes interface state transitions and emits the command array broadcast back
to the HUD. Produces the outbound action-command contract (threat level +
UI commands + enriched context).
"""

from __future__ import annotations

import logging

from graph.argusx_state import ArgusXState
from graph.nodes.argusx_base_node import ArgusXBaseNode

logger = logging.getLogger("argusx.graph.routing_engine")


class ArgusXRoutingEngineNode(ArgusXBaseNode):
    name = "routing_engine"

    async def run(self, state: ArgusXState) -> dict:
        # TODO: derive threat level from hazards + spatial context and map to UI commands.
        hazards = state.get("hazards", [])
        threat_level = "CRITICAL" if hazards else "NORMAL"
        logger.debug("Routing engine resolved threat_level=%s.", threat_level)
        return {
            "threat_level": threat_level,
            "ui_commands": [],
            "enriched_context": state.get("enriched_context", ""),
        }
