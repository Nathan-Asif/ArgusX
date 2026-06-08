"""HTTP client for the ArgusX /navigation/resolve endpoint."""

from __future__ import annotations

from typing import Any

import httpx


class ArgusXRouteClient:
    """Resolves driving routes through the FastAPI backend (Google Maps)."""

    def __init__(self, api_base: str, timeout: float = 15.0) -> None:
        self.api_base = api_base.rstrip("/")
        self.timeout = timeout

    def resolve(
        self,
        origin: dict[str, Any],
        destination: dict[str, Any],
        *,
        step_index: int = 0,
    ) -> dict[str, Any]:
        origin_payload: dict[str, Any] = {}
        if origin.get("label"):
            origin_payload["label"] = origin["label"]
        if origin.get("lat") is not None:
            origin_payload["lat"] = origin["lat"]
        if origin.get("lng") is not None:
            origin_payload["lng"] = origin["lng"]

        payload = {
            "origin": origin_payload,
            "destination": destination,
            "step_index": step_index,
        }
        with httpx.Client(timeout=self.timeout) as client:
            response = client.post(f"{self.api_base}/navigation/resolve", json=payload)
            response.raise_for_status()
            return response.json()
