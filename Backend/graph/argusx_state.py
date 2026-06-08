"""Shared state object that flows through the ArgusX LangGraph."""

from __future__ import annotations

from typing import Any, Literal, TypedDict

ThreatLevel = Literal["NORMAL", "WARNING", "CRITICAL"]
HudMode = Literal["Standby", "Sentry_Active", "Hazard_Alert", "Navigation"]
NavArrow = Literal["LEFT", "RIGHT", "STRAIGHT", "U_TURN"]
NavigationSource = Literal[
    "google_directions",
    "hazard_override",
    "zone_context",
    "standby",
    "client",
]


class Coordinates(TypedDict, total=False):
    lat: float
    lng: float


class Destination(TypedDict, total=False):
    lat: float
    lng: float
    label: str


class RouteContext(TypedDict, total=False):
    """Active map maneuver — from Google Directions or the Flutter client."""

    arrow: NavArrow
    instruction: str
    distance_m: int
    duration_s: int
    step_index: int
    total_steps: int
    maneuver: str
    source: str


class RouteVisualization(TypedDict, total=False):
    """Polyline + destination for the bottom-right route map panel."""

    polyline: str
    origin: Destination
    destination: Destination
    static_map_url: str
    distance_remaining_m: int
    leg_distance_m: int
    step_index: int
    total_steps: int
    source: str


class Navigation(TypedDict, total=False):
    instruction: str
    arrow: NavArrow
    voice_prompt: str
    distance_m: int
    source: NavigationSource
    override_reason: str


class ArgusXState(TypedDict, total=False):
    """End-to-end state for a single Safety Pulse evaluation."""

    # --- Inbound (client telemetry) ---
    speed: float
    coordinates: Coordinates
    frame_data: str
    destination: Destination
    route_context: RouteContext
    route_visualization: RouteVisualization

    # --- Intermediate (produced by nodes) ---
    hazards: list[dict[str, Any]]
    spatial_context: list[dict[str, Any]]
    perception_source: str

    # --- Outbound (action command) ---
    threat_level: ThreatLevel
    ui_commands: list[str]
    enriched_context: str
    hud_mode: HudMode
    navigation: Navigation
    pinned_pois: list[dict[str, Any]]
