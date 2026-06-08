"""Static fixture loader for Safety Pulse test scenarios and spatial zones."""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path
from typing import Any

FIXTURES_DIR = Path(__file__).resolve().parent.parent / "scripts" / "fixtures"


@lru_cache
def load_pulse_scenarios() -> dict[str, dict[str, Any]]:
    path = FIXTURES_DIR / "safety_pulse_scenarios.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    return {item["frame_token"]: item for item in data.get("scenarios", [])}


@lru_cache
def load_spatial_zones() -> list[dict[str, Any]]:
    path = FIXTURES_DIR / "spatial_zones.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    return list(data.get("zones", []))


def resolve_frame_token(frame_data: str) -> str:
    """Map inbound frame payloads to a fixture token when applicable."""
    if not frame_data:
        return "fixture:normal_clear"
    if frame_data.startswith("fixture:"):
        return frame_data
    if frame_data in {"static-test-frame", "test-frame"}:
        return "fixture:normal_clear"
    return frame_data
