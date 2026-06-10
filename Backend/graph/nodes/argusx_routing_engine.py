"""Routing engine agent — Node 3: threat level, HUD mode, navigation, UI commands."""

from __future__ import annotations

import logging

from graph.argusx_state import (
    ArgusXState,
    HudMode,
    NavArrow,
    Navigation,
    RouteContext,
    ThreatLevel,
)
from graph.nodes.argusx_base_node import ArgusXBaseNode

logger = logging.getLogger("argusx.graph.routing_engine")

_SEVERITY_RANK = {"NORMAL": 0, "WARNING": 1, "CRITICAL": 2}


class ArgusXRoutingEngineNode(ArgusXBaseNode):
    name = "routing_engine"

    async def run(self, state: ArgusXState) -> dict:
        hazards = state.get("hazards", [])
        speed = float(state.get("speed", 0.0))
        spatial_context = state.get("spatial_context", [])
        enriched_context = state.get("enriched_context", "")
        route_context = state.get("route_context")
        destination = state.get("destination")

        threat_level = self._resolve_threat_level(hazards)
        hud_mode = self._resolve_hud_mode(threat_level, speed, destination, route_context)
        ui_commands = self._resolve_ui_commands(threat_level, speed, destination)
        navigation = self._resolve_navigation(
            threat_level,
            hazards,
            spatial_context,
            speed,
            route_context,
            destination,
        )

        logger.info(
            "Routing: threat=%s hud_mode=%s nav_source=%s",
            threat_level,
            hud_mode,
            navigation.get("source"),
        )
        return {
            "threat_level": threat_level,
            "hud_mode": hud_mode,
            "ui_commands": ui_commands,
            "enriched_context": enriched_context,
            "navigation": navigation,
        }

    def _resolve_threat_level(self, hazards: list[dict]) -> ThreatLevel:
        if not hazards:
            return "NORMAL"

        top = max(
            hazards,
            key=lambda h: _SEVERITY_RANK.get(str(h.get("severity", "WARNING")).upper(), 1),
        )
        severity = str(top.get("severity", "WARNING")).upper()
        if severity == "CRITICAL":
            return "CRITICAL"
        if severity in {"WARNING", "CRITICAL"}:
            return "WARNING"
        return "WARNING" if hazards else "NORMAL"

    def _resolve_hud_mode(
        self,
        threat_level: ThreatLevel,
        speed: float,
        destination: dict | None,
        route_context: RouteContext | None,
    ) -> HudMode:
        if threat_level == "CRITICAL":
            return "Hazard_Alert"
        if threat_level == "WARNING":
            return "Hazard_Alert"
        if destination or route_context:
            return "Navigation"
        if speed <= 0:
            return "Standby"
        if speed >= 25:
            return "Navigation"
        return "Sentry_Active"

    def _resolve_ui_commands(
        self,
        threat_level: ThreatLevel,
        speed: float,
        destination: dict | None,
    ) -> list[str]:
        commands: list[str] = []
        if threat_level in {"WARNING", "CRITICAL"}:
            commands.append("TRIGGER_HUD_ALERTS")
        if threat_level == "CRITICAL" or speed >= 70:
            commands.append("PRUNE_NON_ESSENTIAL_WIDGETS")
        if destination:
            commands.append("SHOW_ROUTE_MAP")
        return commands

    def _resolve_navigation(
        self,
        threat_level: ThreatLevel,
        hazards: list[dict],
        spatial_context: list[dict],
        speed: float,
        route_context: RouteContext | None,
        destination: dict | None,
    ) -> Navigation:
        if speed <= 0 and not route_context:
            return {
                "instruction": "System standby — awaiting movement",
                "arrow": "STRAIGHT",
                "voice_prompt": "ArgusX standby mode active.",
                "source": "standby",
            }

        hazard_nav = self._hazard_navigation(threat_level, hazards)
        if hazard_nav and threat_level == "CRITICAL":
            hazard_nav["override_reason"] = "Critical hazard overrides map route"
            return hazard_nav

        if route_context:
            map_nav = self._map_navigation(route_context, destination)
            if hazard_nav and threat_level == "WARNING":
                map_nav["hazard_advisory"] = hazard_nav.get("voice_prompt", "")
                map_nav["override_reason"] = "Map route with hazard advisory"
            return map_nav

        if hazard_nav:
            return hazard_nav

        return self._zone_navigation(spatial_context)

    def _map_navigation(
        self,
        route_context: RouteContext,
        destination: dict | None,
    ) -> Navigation:
        arrow = str(route_context.get("arrow", "STRAIGHT")).upper()
        if arrow not in {"LEFT", "RIGHT", "STRAIGHT", "U_TURN"}:
            arrow = "STRAIGHT"

        distance_m = int(route_context.get("distance_m", 0))
        base_instruction = str(route_context.get("instruction", "Continue on route"))
        dest_label = (destination or {}).get("label", "destination")

        # Keep instruction stable per step — client handles distance milestones for TTS.
        instruction = base_instruction
        if distance_m > 0:
            distance_voice = _format_distance_voice(distance_m)
            voice = f"{distance_voice}, {base_instruction}. Heading to {dest_label}."
        else:
            voice = f"{base_instruction}. Heading to {dest_label}."

        source = str(route_context.get("source", "google_directions"))
        nav_source = "client" if source == "client" else "google_directions"

        return {
            "instruction": instruction,
            "arrow": arrow,  # type: ignore[typeddict-item]
            "voice_prompt": voice,
            "distance_m": distance_m,
            "source": nav_source,
        }

    def _hazard_navigation(self, threat_level: ThreatLevel, hazards: list[dict]) -> Navigation | None:
        if not hazards:
            return None

        arrow: NavArrow = "STRAIGHT"
        instruction = "Hazard detected ahead"
        voice = "Caution. Hazard detected."

        hazard_type = hazards[0].get("type", "")
        if hazard_type in {"cross_traffic", "opening_door"}:
            arrow = "LEFT"
            instruction = "Prepare to shift left — hazard on right"
            voice = "Shift left. Hazard detected on your right."
        elif hazard_type in {"debris", "distracted_pedestrian"}:
            arrow = "RIGHT"
            instruction = "Prepare to shift right — center lane obstruction"
            voice = "Shift right. Obstruction ahead in center lane."
        elif threat_level == "CRITICAL":
            arrow = "U_TURN"
            instruction = "Critical hazard — reduce speed immediately"
            voice = "Critical hazard ahead. Reduce speed now."

        return {
            "instruction": instruction,
            "arrow": arrow,
            "voice_prompt": voice,
            "source": "hazard_override",
        }

    def _zone_navigation(self, spatial_context: list[dict]) -> Navigation:
        arrow: NavArrow = "STRAIGHT"
        instruction = "Continue on current bearing"
        voice = "Continue straight."

        if spatial_context:
            zone = spatial_context[0]
            profile = zone.get("risk_profile", "low")
            label = zone.get("label", "mapped zone")
            if profile == "high":
                arrow = "LEFT"
                instruction = f"Caution through {label} — elevated incident history"
                voice = f"Caution. Entering {label}."
            else:
                instruction = f"Proceed through {label}"
                voice = f"Proceeding through {label}."

        return {
            "instruction": instruction,
            "arrow": arrow,
            "voice_prompt": voice,
            "source": "zone_context",
        }


def _format_distance_voice(distance_m: int) -> str:
    """Human-friendly distance phrasing for TTS."""
    if distance_m >= 1000:
        km = distance_m / 1000
        if km >= 10:
            return f"In {km:.0f} kilometers"
        return f"In {km:.1f} kilometers"
    return f"In {distance_m} meters"
