"""Context RAG node — Node 2 of the ArgusX agent graph.

Ingests coordinates and queries the local FAISS index to append spatial
profiles, track anomalies, or fetch historical route-safety metrics. The vector
store is injected so this node never reaches for globals.
"""

from __future__ import annotations

import logging

from graph.argusx_state import ArgusXState
from graph.nodes.argusx_base_node import ArgusXBaseNode
from vector_store.argusx_faiss_store import ArgusXVectorStore

logger = logging.getLogger("argusx.graph.context_rag")


class ArgusXContextRagNode(ArgusXBaseNode):
    name = "context_rag"

    def __init__(self, vector_store: ArgusXVectorStore) -> None:
        self._vector_store = vector_store

    async def run(self, state: ArgusXState) -> dict:
        # TODO: embed coordinates/hazards and query self._vector_store.search(...).
        logger.debug("Context RAG node received coordinates=%s.", state.get("coordinates"))
        return {"spatial_context": [], "enriched_context": ""}
