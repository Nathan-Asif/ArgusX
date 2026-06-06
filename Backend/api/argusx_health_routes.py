"""Health & readiness routes for the ArgusX orchestrator.

Implemented as a class so the router can carry references to the systems it
reports on (database, vector store) instead of relying on module globals.
"""

from __future__ import annotations

from fastapi import APIRouter

from config.argusx_settings import ArgusXSettings
from database.argusx_database import ArgusXDatabase
from vector_store.argusx_faiss_store import ArgusXVectorStore


class ArgusXHealthRoutes:
    """Builds the ``/health`` router bound to the live subsystems."""

    def __init__(
        self,
        settings: ArgusXSettings,
        database: ArgusXDatabase,
        vector_store: ArgusXVectorStore,
    ) -> None:
        self._settings = settings
        self._database = database
        self._vector_store = vector_store
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
            }
