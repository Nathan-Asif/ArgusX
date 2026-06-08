"""Live Google Maps navigation test via the FastAPI backend.

Requires:
  - ARGUSX_GOOGLE_MAPS_API_KEY in .env
  - FastAPI running on port 8000 (start_servers.ps1)

Usage:
    uv run python scripts/test_google_navigation_live.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

ORIGIN = {"label": "Nazimabad, Karachi"}
DESTINATION = {"label": "Saddar, Karachi"}
API_BASE = "http://127.0.0.1:8000"


def main() -> None:
    print("Checking /health ...")
    with httpx.Client(timeout=15.0) as client:
        health = client.get(f"{API_BASE}/health").json()
        maps_status = health.get("google_maps", {})
        print(json.dumps(maps_status, indent=2))
        if not maps_status.get("configured"):
            print("\nERROR: ARGUSX_GOOGLE_MAPS_API_KEY is not configured in .env")
            sys.exit(1)

        print("\nResolving Nazimabad -> Saddar via Google Directions ...")
        response = client.post(
            f"{API_BASE}/navigation/resolve",
            json={"origin": ORIGIN, "destination": DESTINATION},
        )
        if response.status_code != 200:
            print(f"ERROR {response.status_code}: {response.text}")
            sys.exit(1)

        data = response.json()
        origin = data.get("origin", {})
        ctx = data.get("route_context", {})
        viz = data.get("route_visualization", {})
        print("\n--- geocoded origin ---")
        print(json.dumps(origin, indent=2))
        print("\n--- route_context ---")
        print(json.dumps(ctx, indent=2))
        print("\n--- route_visualization (polyline truncated) ---")
        poly = viz.get("polyline", "")
        print(json.dumps({**viz, "polyline": f"{poly[:60]}..." if len(poly) > 60 else poly}, indent=2))
        print("\nGoogle Maps live navigation: OK")


if __name__ == "__main__":
    main()
