"""Perception node — Node 1 of the ArgusX agent graph.

Proxies the live multimedia feed into the Gemini Live orchestration layer to
extract a hazard array (e.g. opening vehicle doors, distracted pedestrians).
Model wiring is stubbed for now; the contract and graph placement are final.
"""

from __future__ import annotations

import logging

from config.argusx_settings import ArgusXSettings
from graph.argusx_state import ArgusXState
from graph.nodes.argusx_base_node import ArgusXBaseNode

logger = logging.getLogger("argusx.graph.perception")


class ArgusXPerceptionNode(ArgusXBaseNode):
    name = "perception"

    def __init__(self, settings: ArgusXSettings) -> None:
        self._settings = settings

    async def run(self, state: ArgusXState) -> dict:
        # TODO: send state["frame_data"] to the Gemini Live model and parse hazards.
        logger.debug("Perception node received frame (speed=%s).", state.get("speed"))
        return {"hazards": []}
