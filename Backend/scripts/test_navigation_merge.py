"""Test map navigation merge with hazard overrides (no Google API required).

Usage:
    uv run python scripts/test_navigation_merge.py
"""

from __future__ import annotations

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

FIXTURE_PATH = Path(__file__).resolve().parent / "fixtures" / "karachi_navigation.json"


async def main() -> None:
    nav_fixture = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))["nazimabad_to_saddar"]
    scenarios = load_pulse_scenarios()

    settings = get_settings()
    database = ArgusXDatabase(settings)
    vector_store = ArgusXVectorStore(settings)
    await vector_store.load()
    graph = ArgusXAgentGraph(settings, database, vector_store)
    graph.build()

    cases = [
        ("map_only", "normal_clear"),
        ("map_plus_warning_hazard", "warning_cross_traffic"),
        ("map_overridden_by_critical", "critical_debris"),
    ]

    for label, scenario_id in cases:
        scenario = next(s for s in scenarios.values() if s["id"] == scenario_id)
        state: ArgusXState = {
            "speed": 35.0,
            "coordinates": nav_fixture["origin"],
            "frame_data": scenario["frame_token"],
            "destination": nav_fixture["destination"],
            "route_context": nav_fixture["route_context"],
            "route_visualization": nav_fixture["route_visualization"],
        }
        result = await graph.ainvoke(state)
        print(f"\n{'=' * 60}")
        print(label.upper())
        print("=" * 60)
        print(json.dumps(
            {
                "threat_level": result.get("threat_level"),
                "hud_mode": result.get("hud_mode"),
                "navigation": result.get("navigation"),
                "ui_commands": result.get("ui_commands"),
                "pinned_pois": result.get("pinned_pois"),
            },
            indent=2,
        ))

    await vector_store.unload()


if __name__ == "__main__":
    asyncio.run(main())
