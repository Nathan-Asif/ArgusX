"""Gemini multimodal client for the Perception agent."""

from __future__ import annotations

import base64
import json
import logging
import re
from typing import Any, Optional

from config.argusx_settings import ArgusXSettings

logger = logging.getLogger("argusx.gemini")

PERCEPTION_PROMPT = """Analyze this road-rider camera frame for immediate safety hazards.
Return ONLY valid JSON with this shape:
{"hazards":[{"type":"string","severity":"NORMAL|WARNING|CRITICAL","confidence":0.0,"description":"string"}]}
If no hazards are visible, return {"hazards":[]}.
Focus on: opening vehicle doors, pedestrians, debris, cross-traffic, sudden obstructions."""


class ArgusXGeminiClient:
    """Thin wrapper around google-genai for hazard extraction."""

    def __init__(self, settings: ArgusXSettings) -> None:
        self._settings = settings
        self._client: Any = None

    @property
    def is_configured(self) -> bool:
        return bool(self._settings.gemini_api_key)

    def _get_client(self) -> Any:
        if self._client is None:
            from google import genai

            self._client = genai.Client(api_key=self._settings.gemini_api_key)
        return self._client

    async def extract_hazards(self, frame_data: str) -> list[dict[str, Any]]:
        """Send a base64 image frame to Gemini and parse hazard JSON."""
        if not self.is_configured:
            return []

        raw = frame_data.strip()
        if raw.startswith("fixture:") or raw in {"static-test-frame", "test-frame"}:
            return []

        try:
            image_bytes = base64.b64decode(raw, validate=True)
        except Exception:
            logger.debug("Frame data is not valid base64; skipping Gemini call.")
            return []

        if len(image_bytes) < 128:
            logger.debug("Frame too small for Gemini analysis; skipping.")
            return []

        try:
            from google.genai import types

            client = self._get_client()
            response = client.models.generate_content(
                model=self._settings.gemini_model,
                contents=[
                    types.Content(
                        parts=[
                            types.Part(text=PERCEPTION_PROMPT),
                            types.Part(
                                inline_data=types.Blob(
                                    mime_type="image/png",
                                    data=image_bytes,
                                )
                            ),
                        ]
                    )
                ],
            )
            return self._parse_hazards(response.text or "")
        except Exception as exc:
            logger.warning("Gemini perception call failed: %s", exc)
            return []

    def _parse_hazards(self, text: str) -> list[dict[str, Any]]:
        cleaned = text.strip()
        fence = re.search(r"```(?:json)?\s*([\s\S]*?)```", cleaned)
        if fence:
            cleaned = fence.group(1).strip()

        try:
            payload = json.loads(cleaned)
        except json.JSONDecodeError:
            logger.warning("Gemini returned non-JSON perception output.")
            return []

        hazards = payload.get("hazards", [])
        if not isinstance(hazards, list):
            return []
        return [h for h in hazards if isinstance(h, dict)]
