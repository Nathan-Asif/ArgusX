"""REST routes for resolving map navigation (source → destination)."""

from __future__ import annotations

import logging
from typing import Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from graph.argusx_state import Destination
from services.argusx_google_maps_client import ArgusXGoogleMapsClient

logger = logging.getLogger("argusx.api.navigation")


class NavigationPoint(BaseModel):
    lat: float | None = None
    lng: float | None = None
    label: str | None = None


class NavigationResolveRequest(BaseModel):
    origin: NavigationPoint
    destination: NavigationPoint
    step_index: int = Field(default=0, ge=0)


class ArgusXNavigationRoutes:
    """Exposes ``POST /navigation/resolve`` for Flutter route setup."""

    def __init__(self, maps_client: ArgusXGoogleMapsClient) -> None:
        self._maps_client = maps_client
        self.router = APIRouter(prefix="/navigation", tags=["navigation"])
        self._register()

    def _register(self) -> None:
        @self.router.post("/resolve")
        async def resolve_navigation(body: NavigationResolveRequest) -> dict[str, Any]:
            if not self._maps_client.is_configured:
                raise HTTPException(
                    status_code=503,
                    detail="Google Maps API key not configured. Set ARGUSX_GOOGLE_MAPS_API_KEY in .env",
                )

            resolved = await self._maps_client.resolve_route(
                body.origin.model_dump(exclude_none=True),
                body.destination.model_dump(exclude_none=True),
                step_index=body.step_index,
            )
            if resolved is None:
                raise HTTPException(
                    status_code=422,
                    detail="Could not resolve route for the given origin and destination.",
                )

            route_context, route_visualization, resolved_origin = resolved
            logger.info(
                "Navigation resolved: %s -> %s (step %d/%d)",
                resolved_origin.get("label", body.origin.label),
                route_visualization.get("destination", {}).get("label", "destination"),
                route_context.get("step_index", 0),
                route_context.get("total_steps", 0),
            )
            return {
                "origin": resolved_origin,
                "route_context": route_context,
                "route_visualization": route_visualization,
                "destination": route_visualization.get("destination"),
            }

        @self.router.get("/map_image")
        async def get_map_image(
            lat: float,
            lng: float,
            dest_lat: float,
            dest_lng: float,
            polyline: str,
        ):
            if not self._maps_client.is_configured:
                raise HTTPException(
                    status_code=503,
                    detail="Google Maps API key not configured.",
                )

            url = self._maps_client.build_static_map_url(
                {"lat": lat, "lng": lng, "label": "Rider"},
                {"lat": dest_lat, "lng": dest_lng, "label": "Destination"},
                polyline,
            )
            if not url:
                raise HTTPException(status_code=400, detail="Could not build map URL")

            from fastapi.responses import RedirectResponse
            return RedirectResponse(url)
