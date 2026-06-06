"""Application composition root for the ArgusX backend.

``ArgusXApplication`` is the single place where every subsystem is constructed
and wired together. It owns dependency creation (settings -> database / vector
store -> agent graph -> routers), manages their lifecycle through the FastAPI
lifespan, and exposes the assembled ``FastAPI`` instance via ``.app``.

Keeping this as a class means the whole orchestrator can be instantiated,
inspected, and tested as one object, while each subsystem stays independently
swappable.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.argusx_health_routes import ArgusXHealthRoutes
from api.argusx_websocket_routes import ArgusXWebSocketRoutes
from config.argusx_settings import ArgusXSettings, get_settings
from database.argusx_database import ArgusXDatabase
from graph.argusx_agent_graph import ArgusXAgentGraph
from vector_store.argusx_faiss_store import ArgusXVectorStore

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("argusx.core")


class ArgusXApplication:
    """Builds, wires, and lifecycle-manages the ArgusX FastAPI orchestrator."""

    def __init__(self, settings: ArgusXSettings | None = None) -> None:
        self.settings = settings or get_settings()

        # --- Subsystems (composition root) ---
        self.database = ArgusXDatabase(self.settings)
        self.vector_store = ArgusXVectorStore(self.settings)
        self.agent_graph = ArgusXAgentGraph(
            settings=self.settings,
            database=self.database,
            vector_store=self.vector_store,
        )

        # --- HTTP application ---
        self.app = FastAPI(
            title=self.settings.app_name,
            debug=self.settings.debug,
            lifespan=self._lifespan,
        )
        self._configure_middleware()
        self._register_routes()

    def _configure_middleware(self) -> None:
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=self.settings.cors_origin_list,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    def _register_routes(self) -> None:
        health_routes = ArgusXHealthRoutes(
            settings=self.settings,
            database=self.database,
            vector_store=self.vector_store,
        )
        websocket_routes = ArgusXWebSocketRoutes(agent_graph=self.agent_graph)

        self.app.include_router(health_routes.router)
        self.app.include_router(websocket_routes.router)

    @asynccontextmanager
    async def _lifespan(self, app: FastAPI):
        """Bring every subsystem up on startup and tear it down on shutdown."""
        logger.info("ArgusX orchestrator starting up...")
        await self.database.connect()
        await self.vector_store.load()
        self.agent_graph.build()
        logger.info("ArgusX orchestrator ready.")
        try:
            yield
        finally:
            logger.info("ArgusX orchestrator shutting down...")
            await self.vector_store.unload()
            await self.database.disconnect()


def create_app() -> FastAPI:
    """Factory used by ASGI servers (e.g. ``uvicorn argusx_main:app``)."""
    return ArgusXApplication().app
