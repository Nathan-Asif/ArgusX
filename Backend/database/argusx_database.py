"""Relational data-layer system for ArgusX.

``ArgusXDatabase`` is the single owner of the Supabase / PostgreSQL connection.
It is intentionally a thin lifecycle wrapper for now (connect / disconnect /
health) so concrete query methods can be added later without changing how the
rest of the application acquires the database. The client is created lazily so
the orchestrator can boot even before Supabase credentials are provided.
"""

from __future__ import annotations

import logging
from typing import Any, Optional

from config.argusx_settings import ArgusXSettings

logger = logging.getLogger("argusx.database")


class ArgusXDatabase:
    """Lifecycle manager and access point for the Supabase relational layer."""

    def __init__(self, settings: ArgusXSettings) -> None:
        self._settings = settings
        self._client: Optional[Any] = None
        self._connected: bool = False

    @property
    def is_connected(self) -> bool:
        return self._connected

    @property
    def client(self) -> Any:
        """Return the live Supabase client, raising if not yet connected."""
        if self._client is None:
            raise RuntimeError("ArgusXDatabase.connect() must be called before use.")
        return self._client

    async def connect(self) -> None:
        """Establish the Supabase client handshake.

        Skips gracefully (with a warning) when credentials are absent so local
        development without a database stays unblocked.
        """
        if self._connected:
            return

        if not (self._settings.supabase_url and self._settings.supabase_key):
            logger.warning("Supabase credentials missing; running without a database connection.")
            return

        try:
            from supabase import create_client  # lazy import — optional dependency
        except ImportError:
            logger.warning("`supabase` package not installed; skipping database connection.")
            return

        self._client = create_client(self._settings.supabase_url, self._settings.supabase_key)
        self._connected = True
        logger.info("ArgusXDatabase connected to Supabase.")

    async def disconnect(self) -> None:
        """Release the client reference during application shutdown."""
        self._client = None
        self._connected = False
        logger.info("ArgusXDatabase disconnected.")

    async def health_check(self) -> dict[str, Any]:
        """Report the current connectivity status for the health endpoint."""
        return {
            "configured": bool(self._settings.supabase_url and self._settings.supabase_key),
            "connected": self._connected,
        }
