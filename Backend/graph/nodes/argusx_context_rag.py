"""Context RAG agent — Node 2: spatial zone lookup via FAISS."""

from __future__ import annotations

import logging

from graph.argusx_state import ArgusXState
from graph.nodes.argusx_base_node import ArgusXBaseNode
from vector_store.argusx_faiss_store import ArgusXVectorStore

logger = logging.getLogger("argusx.graph.context_rag")


class ArgusXContextRagNode(ArgusXBaseNode):
    name = "context_rag"

    def __init__(self, vector_store: ArgusXVectorStore) -> None:
        self._vector_store = vector_store

    async def run(self, state: ArgusXState) -> dict:
        coordinates = state.get("coordinates") or {}
        lat = float(coordinates.get("lat", 0.0))
        lng = float(coordinates.get("lng", 0.0))
        speed = float(state.get("speed", 0.0))
        hazards = state.get("hazards", [])
        destination = state.get("destination")
        route_context = state.get("route_context")

        google_nav = bool(
            route_context
            and str(route_context.get("source", "")) in {"google_directions", "client"}
        )
        spatial_context: list[dict] = []
        if not google_nav:
            spatial_context = await self._vector_store.search(lat, lng, speed=speed, top_k=2)

        enriched_context = self._build_context(
            spatial_context,
            hazards,
            destination,
            route_context,
            google_nav=google_nav,
        )

        logger.info(
            "Context RAG at (%.4f, %.4f) -> %d zone(s).",
            lat,
            lng,
            len(spatial_context),
        )
        return {
            "spatial_context": spatial_context,
            "enriched_context": enriched_context,
            "pinned_pois": self._build_pinned_pois(
                spatial_context,
                hazards,
                destination,
                google_nav=google_nav,
            ),
        }

    def _build_context(
        self,
        spatial_context: list[dict],
        hazards: list[dict],
        destination: dict | None = None,
        route_context: dict | None = None,
        *,
        google_nav: bool = False,
    ) -> str:
        parts: list[str] = []

        if destination and destination.get("label"):
            parts.append(f"Navigating to {destination['label']}.")

        if route_context:
            distance_m = route_context.get("distance_m")
            instruction = route_context.get("instruction")
            if distance_m:
                parts.append(f"Next maneuver in {distance_m} m.")
            if instruction and google_nav:
                parts.append(str(instruction))

        if hazards:
            lead = hazards[0]
            parts.append(lead.get("description") or f"Hazard detected: {lead.get('type', 'unknown')}")

        if spatial_context and not google_nav:
            zone = spatial_context[0]
            parts.append(
                f"Near {zone.get('label', 'mapped zone')} "
                f"({zone.get('risk_profile', 'unknown')} risk, "
                f"{zone.get('historical_incidents', 0)} prior incidents)."
            )

        return " ".join(parts) if parts else "Safety corridor verified. No immediate spatial anomalies."

    def _build_pinned_pois(
        self,
        spatial_context: list[dict],
        hazards: list[dict],
        destination: dict | None = None,
        *,
        google_nav: bool = False,
    ) -> list[dict]:
        pins: list[dict] = []
        if destination and destination.get("lat") is not None and destination.get("lng") is not None:
            pins.append(
                {
                    "label": destination.get("label", "Destination"),
                    "lat": destination.get("lat"),
                    "lng": destination.get("lng"),
                    "pin_type": "destination",
                }
            )
        if google_nav:
            for hazard in hazards[:1]:
                pins.append(
                    {
                        "label": hazard.get("type", "hazard"),
                        "description": hazard.get("description", ""),
                        "severity": hazard.get("severity", "WARNING"),
                    }
                )
            return pins

        for zone in spatial_context[:2]:
            pins.append(
                {
                    "label": zone.get("label"),
                    "lat": zone.get("lat"),
                    "lng": zone.get("lng"),
                    "risk_profile": zone.get("risk_profile"),
                }
            )
        for hazard in hazards[:1]:
            pins.append(
                {
                    "label": hazard.get("type", "hazard"),
                    "description": hazard.get("description", ""),
                    "severity": hazard.get("severity", "WARNING"),
                }
            )
        return pins
