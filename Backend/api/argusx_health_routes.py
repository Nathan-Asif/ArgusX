"""Health & readiness routes for the ArgusX orchestrator.

Implemented as a class so the router can carry references to the systems it
reports on (database, vector store) instead of relying on module globals.
"""

from __future__ import annotations

from fastapi import APIRouter

from config.argusx_settings import ArgusXSettings
from database.argusx_database import ArgusXDatabase
from services.argusx_compliance_client import ArgusXComplianceClient
from services.argusx_google_maps_client import ArgusXGoogleMapsClient
from vector_store.argusx_faiss_store import ArgusXVectorStore


class ArgusXHealthRoutes:
    """Builds the ``/health`` router bound to the live subsystems."""

    def __init__(
        self,
        settings: ArgusXSettings,
        database: ArgusXDatabase,
        vector_store: ArgusXVectorStore,
        compliance_client: ArgusXComplianceClient,
        maps_client: ArgusXGoogleMapsClient,
    ) -> None:
        self._settings = settings
        self._database = database
        self._vector_store = vector_store
        self._compliance_client = compliance_client
        self._maps_client = maps_client
        self.router = APIRouter(tags=["health"])
        self._register()

    def _register(self) -> None:
        @self.router.get("/health")
        async def health() -> dict:
            return {
                "status": "ok",
                "app": self._settings.app_name,
                "environment": self._settings.environment,
                "database": await self._database.health_check(),
                "vector_store": await self._vector_store.health_check(),
                "compliance_service": await self._compliance_client.health_check(),
                "google_maps": await self._maps_client.health_check(),
            }
