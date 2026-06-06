"""Local low-latency vector store system for ArgusX.

``ArgusXVectorStore`` owns the FAISS index used by the Context RAG node to fetch
spatial profiles and historical route-safety metrics. FAISS is imported lazily
so the orchestrator boots without the native dependency present; concrete
add/search implementations are stubbed for now and will be filled in later.
"""

from __future__ import annotations

import logging
import os
from typing import Any, Optional

from config.argusx_settings import ArgusXSettings

logger = logging.getLogger("argusx.vector_store")


class ArgusXVectorStore:
    """Lifecycle manager for the on-disk FAISS embedding index."""

    def __init__(self, settings: ArgusXSettings) -> None:
        self._settings = settings
        self._index: Optional[Any] = None
        self._ready: bool = False

    @property
    def is_ready(self) -> bool:
        return self._ready

    @property
    def dimension(self) -> int:
        return self._settings.vector_dimension

    async def load(self) -> None:
        """Load an existing FAISS index from disk, or defer creation until needed."""
        if self._ready:
            return

        try:
            import faiss  # lazy import — optional native dependency
        except ImportError:
            logger.warning("`faiss` package not installed; vector store running in no-op mode.")
            return

        index_path = self._settings.vector_index_path
        if os.path.exists(index_path):
            self._index = faiss.read_index(index_path)
            logger.info("Loaded FAISS index from %s", index_path)
        else:
            self._index = faiss.IndexFlatL2(self._settings.vector_dimension)
            logger.info("Initialized empty FAISS index (dim=%d).", self._settings.vector_dimension)

        self._ready = True

    async def search(self, embedding: list[float], top_k: int = 5) -> list[dict[str, Any]]:
        """Return nearest-neighbour context for an embedding.

        Placeholder: wiring is in place; ranking logic is added with the RAG node.
        """
        if not self._ready or self._index is None:
            return []
        return []

    async def unload(self) -> None:
        """Drop the in-memory index reference during shutdown."""
        self._index = None
        self._ready = False
        logger.info("ArgusXVectorStore unloaded.")

    async def health_check(self) -> dict[str, Any]:
        return {"ready": self._ready, "dimension": self._settings.vector_dimension}
