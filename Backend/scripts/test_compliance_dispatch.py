"""Test the FastAPI → Java compliance integration with static data.

Usage (Java service must be running on :8081):
    uv run python scripts/test_compliance_dispatch.py
    uv run python scripts/test_compliance_dispatch.py --scenario critical
    uv run python scripts/test_compliance_dispatch.py --scenario menu
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path

# Allow running from Backend/ without installing as a package.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config.argusx_settings import get_settings
from graph.argusx_agent_graph import ArgusXAgentGraph
from graph.argusx_state import ArgusXState
from database.argusx_database import ArgusXDatabase
from services.argusx_compliance_client import ArgusXComplianceClient
from vector_store.argusx_faiss_store import ArgusXVectorStore


async def run_warning_dispatch(client: ArgusXComplianceClient) -> None:
    state: ArgusXState = {
        "speed": 48.2,
        "coordinates": {"lat": 37.7749, "lng": -122.4194},
        "frame_data": "static-test-frame",
        "hazards": [{"type": "cross_traffic", "confidence": 0.81}],
        "threat_level": "WARNING",
        "ui_commands": ["TRIGGER_HUD_ALERTS"],
        "enriched_context": "Cross-traffic intersection hazard detected.",
    }
    result = await client.post_threat_event(state, session_id="test-session", rider_id="rider-neo")
    print("\n=== WARNING dispatch result ===")
    print(json.dumps(result, indent=2))


async def run_critical_dispatch(client: ArgusXComplianceClient) -> None:
    state: ArgusXState = {
        "speed": 92.0,
        "coordinates": {"lat": 37.7651, "lng": -122.4411},
        "frame_data": "static-test-frame",
        "hazards": [{"type": "debris", "confidence": 0.94}],
        "threat_level": "CRITICAL",
        "ui_commands": ["TRIGGER_HUD_ALERTS", "PRUNE_NON_ESSENTIAL_WIDGETS"],
        "enriched_context": "CRITICAL: Heavy deceleration ahead. Obstruction in lane.",
    }
    result = await client.post_threat_event(state, session_id="test-session", rider_id="rider-morpheus")
    print("\n=== CRITICAL dispatch result ===")
    print(json.dumps(result, indent=2))


async def run_null_coordinates(client: ArgusXComplianceClient) -> None:
    state: ArgusXState = {
        "speed": 10.0,
        "coordinates": {},
        "threat_level": "WARNING",
        "hazards": [{"type": "sensor_fault", "confidence": 0.5}],
        "enriched_context": "Null coordinate fallback test.",
        "ui_commands": [],
    }
    result = await client.post_threat_event(state, session_id="null-coord-test", rider_id="rider-cypher")
    print("\n=== Null coordinates dispatch result ===")
    print(json.dumps(result, indent=2))


async def run_menu_config(client: ArgusXComplianceClient) -> None:
    result = await client.fetch_menu_config(rider_id="rider-neo")
    print("\n=== Menu config result ===")
    print(json.dumps(result, indent=2))


async def run_graph_plus_dispatch(settings, client: ArgusXComplianceClient) -> None:
    database = ArgusXDatabase(settings)
    vector_store = ArgusXVectorStore(settings)
    graph = ArgusXAgentGraph(settings, database, vector_store)
    graph.build()

    state: ArgusXState = {
        "speed": 65.0,
        "coordinates": {"lat": 37.7833, "lng": -122.4167},
        "frame_data": "static-test-frame",
        "hazards": [{"type": "opening_door", "confidence": 0.88}],
        "enriched_context": "Vehicle door opening on right lane.",
    }
    result = await graph.ainvoke(state)
    result["threat_level"] = "CRITICAL"  # simulate routing output until agent logic is complete
    result["ui_commands"] = ["TRIGGER_HUD_ALERTS", "PRUNE_NON_ESSENTIAL_WIDGETS"]

    print("\n=== LangGraph result ===")
    print(json.dumps(dict(result), indent=2))

    compliance_result = await client.post_threat_event(
        result, session_id="graph-test-session", rider_id="rider-trinity"
    )
    print("\n=== Graph -> compliance dispatch result ===")
    print(json.dumps(compliance_result, indent=2))


async def main() -> None:
    parser = argparse.ArgumentParser(description="Test ArgusX compliance integration")
    parser.add_argument(
        "--scenario",
        choices=["all", "warning", "critical", "null", "menu", "graph"],
        default="all",
    )
    args = parser.parse_args()

    settings = get_settings()
    client = ArgusXComplianceClient(settings)
    await client.startup()

    if not client.is_reachable:
        print(
            "Compliance service not reachable at",
            settings.compliance_service_url,
            "\nStart Java service: cd Microservices/compliance_service && mvn spring-boot:run",
        )
        sys.exit(1)

    print("Compliance service OK:", settings.compliance_service_url)

    if args.scenario in ("all", "warning"):
        await run_warning_dispatch(client)
    if args.scenario in ("all", "critical"):
        await run_critical_dispatch(client)
    if args.scenario in ("all", "null"):
        await run_null_coordinates(client)
    if args.scenario in ("all", "menu"):
        await run_menu_config(client)
    if args.scenario in ("all", "graph"):
        await run_graph_plus_dispatch(settings, client)

    await client.shutdown()


if __name__ == "__main__":
    asyncio.run(main())
