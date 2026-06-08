"""Deterministic pseudo-embeddings for coordinate-based FAISS search."""

from __future__ import annotations

import hashlib

import numpy as np


def telemetry_to_embedding(lat: float, lng: float, speed: float = 0.0, dim: int = 768) -> np.ndarray:
    """Build a stable unit vector from telemetry for local zone matching."""
    seed = int(hashlib.md5(f"{lat:.5f},{lng:.5f},{speed:.1f}".encode()).hexdigest(), 16) % (2**32)
    rng = np.random.default_rng(seed)
    vector = rng.standard_normal(dim, dtype=np.float32)
    vector[0] = lat
    vector[1] = lng
    vector[2] = min(speed / 200.0, 1.0)
    norm = np.linalg.norm(vector)
    if norm > 0:
        vector /= norm
    return vector
