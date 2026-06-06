"""Shared state object that flows through the ArgusX LangGraph.

This is the single, type-safe contract every node reads from and writes to.
The inbound keys mirror the WebSocket telemetry schema; the outbound keys mirror
the action-command schema (see PRD section 6.1). Nodes return partial dicts and
LangGraph merges them into this structure.
"""

from __future__ import annotations

from typing import Any, Literal, TypedDict

ThreatLevel = Literal["NORMAL", "WARNING", "CRITICAL"]


class Coordinates(TypedDict, total=False):
    lat: float
    lng: float


class ArgusXState(TypedDict, total=False):
    """End-to-end state for a single Safety Pulse evaluation."""

    # --- Inbound (client telemetry) ---
    speed: float
    coordinates: Coordinates
    frame_data: str  # base64-encoded camera frame

    # --- Intermediate (produced by nodes) ---
    hazards: list[dict[str, Any]]
    spatial_context: list[dict[str, Any]]

    # --- Outbound (action command) ---
    threat_level: ThreatLevel
    ui_commands: list[str]
    enriched_context: str
