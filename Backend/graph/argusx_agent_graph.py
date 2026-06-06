"""LangGraph core orchestration matrix for ArgusX.

``ArgusXAgentGraph`` owns the construction, compilation, and invocation of the
stateful agent graph. It composes the three node systems into the linear
Safety Pulse pipeline:

    START -> perception -> context_rag -> routing_engine -> END

Dependencies (settings, database, vector store) are injected once and shared
with the nodes, so swapping implementations never touches the wiring. The graph
is compiled lazily and cached, exposing a clean ``ainvoke`` for callers (e.g.
the WebSocket route) without leaking LangGraph internals.
"""

from __future__ import annotations

import logging
from typing import Any, Optional

from langgraph.graph import END, START, StateGraph

from config.argusx_settings import ArgusXSettings
from database.argusx_database import ArgusXDatabase
from graph.argusx_state import ArgusXState
from graph.nodes.argusx_context_rag import ArgusXContextRagNode
from graph.nodes.argusx_perception import ArgusXPerceptionNode
from graph.nodes.argusx_routing_engine import ArgusXRoutingEngineNode
from vector_store.argusx_faiss_store import ArgusXVectorStore

logger = logging.getLogger("argusx.graph")


class ArgusXAgentGraph:
    """Builds and runs the compiled LangGraph state machine."""

    def __init__(
        self,
        settings: ArgusXSettings,
        database: ArgusXDatabase,
        vector_store: ArgusXVectorStore,
    ) -> None:
        self._settings = settings
        self._database = database
        self._vector_store = vector_store

        # Node systems — each is an injectable, self-contained class.
        self._perception = ArgusXPerceptionNode(settings=settings)
        self._context_rag = ArgusXContextRagNode(vector_store=vector_store)
        self._routing_engine = ArgusXRoutingEngineNode()

        self._compiled: Optional[Any] = None

    def build(self) -> Any:
        """Assemble and compile the state graph (idempotent)."""
        if self._compiled is not None:
            return self._compiled

        graph = StateGraph(ArgusXState)
        graph.add_node(self._perception.name, self._perception)
        graph.add_node(self._context_rag.name, self._context_rag)
        graph.add_node(self._routing_engine.name, self._routing_engine)

        graph.add_edge(START, self._perception.name)
        graph.add_edge(self._perception.name, self._context_rag.name)
        graph.add_edge(self._context_rag.name, self._routing_engine.name)
        graph.add_edge(self._routing_engine.name, END)

        self._compiled = graph.compile()
        logger.info("ArgusX agent graph compiled.")
        return self._compiled

    @property
    def compiled(self) -> Any:
        """Return the compiled graph, building it on first access."""
        if self._compiled is None:
            self.build()
        return self._compiled

    async def ainvoke(self, state: ArgusXState) -> ArgusXState:
        """Run a single telemetry frame through the full pipeline."""
        return await self.compiled.ainvoke(state)
