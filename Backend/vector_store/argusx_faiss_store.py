"""Local low-latency vector store system for ArgusX."""

from __future__ import annotations

import logging
import os
from typing import Any, Optional

import numpy as np

from config.argusx_settings import ArgusXSettings
from graph.argusx_fixtures import load_spatial_zones
from vector_store.argusx_embedding import telemetry_to_embedding

logger = logging.getLogger("argusx.vector_store")


class ArgusXVectorStore:
    """Lifecycle manager for the on-disk FAISS embedding index."""

    def __init__(self, settings: ArgusXSettings) -> None:
        self._settings = settings
        self._index: Optional[Any] = None
        self._metadata: list[dict[str, Any]] = []
        self._ready: bool = False

    @property
    def is_ready(self) -> bool:
        return self._ready

    @property
    def dimension(self) -> int:
        return self._settings.vector_dimension

    @property
    def catalog_size(self) -> int:
        return len(self._metadata)

    async def load(self) -> None:
        """Load FAISS index from disk or seed with spatial zone fixtures."""
        if self._ready:
            return

        try:
            import faiss  # lazy import
        except ImportError:
            logger.warning("`faiss` package not installed; vector store running in no-op mode.")
            return

        index_path = self._settings.vector_index_path
        meta_path = f"{index_path}.meta.npy"

        if os.path.exists(index_path) and os.path.exists(meta_path):
            self._index = faiss.read_index(index_path)
            self._metadata = list(np.load(meta_path, allow_pickle=True))
            logger.info("Loaded FAISS index from %s (%d zones)", index_path, len(self._metadata))
        else:
            await self._seed_from_fixtures(faiss)

        self._ready = True

    async def _seed_from_fixtures(self, faiss: Any) -> None:
        zones = load_spatial_zones()
        dim = self._settings.vector_dimension
        self._index = faiss.IndexFlatL2(dim)
        vectors = []
        self._metadata = []

        for zone in zones:
            embedding = telemetry_to_embedding(zone["lat"], zone["lng"], speed=0.0, dim=dim)
            vectors.append(embedding)
            self._metadata.append(zone)

        if vectors:
            matrix = np.vstack(vectors).astype(np.float32)
            self._index.add(matrix)
            logger.info("Seeded FAISS index with %d spatial zones.", len(vectors))

    async def search(
        self,
        lat: float,
        lng: float,
        speed: float = 0.0,
        top_k: int = 3,
    ) -> list[dict[str, Any]]:
        """Return nearest spatial zones for the rider coordinates."""
        if not self._ready or self._index is None or self._index.ntotal == 0:
            return []

        import faiss

        query = telemetry_to_embedding(lat, lng, speed=speed, dim=self._settings.vector_dimension)
        query_matrix = np.array([query], dtype=np.float32)
        k = min(top_k, self._index.ntotal)
        distances, indices = self._index.search(query_matrix, k)

        results: list[dict[str, Any]] = []
        for rank, idx in enumerate(indices[0]):
            if idx < 0 or idx >= len(self._metadata):
                continue
            zone = dict(self._metadata[idx])
            zone["distance"] = float(distances[0][rank])
            results.append(zone)
        return results

    async def unload(self) -> None:
        self._index = None
        self._metadata = []
        self._ready = False
        logger.info("ArgusXVectorStore unloaded.")

    async def health_check(self) -> dict[str, Any]:
        return {
            "ready": self._ready,
            "dimension": self._settings.vector_dimension,
            "catalog_size": self.catalog_size,
        }
