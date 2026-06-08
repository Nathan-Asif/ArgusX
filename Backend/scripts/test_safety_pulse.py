"""Test the three-agent LangGraph pipeline with static fixtures.

Usage:
    uv run python scripts/test_safety_pulse.py
    uv run python scripts/test_safety_pulse.py --scenario critical_debris
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config.argusx_settings import get_settings
from database.argusx_database import ArgusXDatabase
from graph.argusx_agent_graph import ArgusXAgentGraph
from graph.argusx_fixtures import load_pulse_scenarios
from graph.argusx_state import ArgusXState
from vector_store.argusx_faiss_store import ArgusXVectorStore

# Coordinates aligned with spatial_zones.json for RAG hits
SCENARIO_COORDS = {
    "normal_clear": {"lat": 37.7749, "lng": -122.4194, "speed": 35.0},
    "warning_cross_traffic": {"lat": 37.7749, "lng": -122.4194, "speed": 48.0},
    "warning_opening_door": {"lat": 37.7599, "lng": -122.4348, "speed": 22.0},
    "critical_debris": {"lat": 37.7651, "lng": -122.4411, "speed": 92.0},
    "critical_pedestrian": {"lat": 37.7833, "lng": -122.4167, "speed": 55.0},
}


async def run_scenario(graph: ArgusXAgentGraph, scenario_id: str) -> dict:
    scenarios = load_pulse_scenarios()
    match = next((s for s in scenarios.values() if s["id"] == scenario_id), None)
    if not match:
        raise ValueError(f"Unknown scenario: {scenario_id}")

    coords = SCENARIO_COORDS.get(scenario_id, {"lat": 37.7749, "lng": -122.4194, "speed": 40.0})
    state: ArgusXState = {
        "speed": coords["speed"],
        "coordinates": {"lat": coords["lat"], "lng": coords["lng"]},
        "frame_data": match["frame_token"],
    }

    result = await graph.ainvoke(state)
    return dict(result)


async def main() -> None:
    parser = argparse.ArgumentParser(description="Test ArgusX Safety Pulse agent graph")
    parser.add_argument(
        "--scenario",
        choices=list(SCENARIO_COORDS.keys()) + ["all"],
        default="all",
    )
    args = parser.parse_args()

    settings = get_settings()
    database = ArgusXDatabase(settings)
    vector_store = ArgusXVectorStore(settings)
    await vector_store.load()

    graph = ArgusXAgentGraph(settings, database, vector_store)
    graph.build()

    scenario_ids = list(SCENARIO_COORDS.keys()) if args.scenario == "all" else [args.scenario]

    for scenario_id in scenario_ids:
        print(f"\n{'=' * 60}")
        print(f"SCENARIO: {scenario_id}")
        print("=" * 60)
        result = await run_scenario(graph, scenario_id)
        print(json.dumps(result, indent=2))

    await vector_store.unload()


if __name__ == "__main__":
    asyncio.run(main())
