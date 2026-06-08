"""Fetch Google Static Maps road tiles for the HUD minimap."""

from __future__ import annotations

import io
from typing import Any

import httpx
import pygame


def fetch_static_map_surface(url: str, width: int, height: int) -> pygame.Surface | None:
    """Download a Static Maps image and return a pygame Surface scaled to the panel."""
    if not url:
        return None
    try:
        with httpx.Client(timeout=15.0) as client:
            response = client.get(url)
            response.raise_for_status()
            image = pygame.image.load(io.BytesIO(response.content))
            return pygame.transform.smoothscale(image, (width, height))
    except Exception:
        return None


def static_map_url_from_visualization(route_visualization: dict[str, Any] | None) -> str:
    if not route_visualization:
        return ""
    return str(route_visualization.get("static_map_url", ""))
