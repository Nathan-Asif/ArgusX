"""Perception agent — Node 1: hazard extraction via fixtures or Gemini."""

from __future__ import annotations

import logging

from config.argusx_settings import ArgusXSettings
from graph.argusx_fixtures import load_pulse_scenarios, resolve_frame_token
from graph.argusx_state import ArgusXState
from graph.nodes.argusx_base_node import ArgusXBaseNode
from services.argusx_gemini_client import ArgusXGeminiClient

logger = logging.getLogger("argusx.graph.perception")


class ArgusXPerceptionNode(ArgusXBaseNode):
    name = "perception"

    def __init__(self, settings: ArgusXSettings) -> None:
        self._settings = settings
        self._gemini = ArgusXGeminiClient(settings)
        self._scenarios = load_pulse_scenarios()

    async def run(self, state: ArgusXState) -> dict:
        frame_data = state.get("frame_data", "")
        token = resolve_frame_token(frame_data)

        if token in self._scenarios:
            scenario = self._scenarios[token]
            hazards = scenario.get("hazards", [])
            logger.info("Perception fixture '%s' -> %d hazard(s).", scenario["id"], len(hazards))
            return {
                "hazards": hazards,
                "perception_source": f"fixture:{scenario['id']}",
            }

        if self._gemini.is_configured:
            hazards = await self._gemini.extract_hazards(frame_data)
            if hazards:
                logger.info("Perception Gemini -> %d hazard(s).", len(hazards))
                return {"hazards": hazards, "perception_source": "gemini"}

        logger.debug("Perception: no hazards (speed=%s).", state.get("speed"))
        return {"hazards": [], "perception_source": "none"}
