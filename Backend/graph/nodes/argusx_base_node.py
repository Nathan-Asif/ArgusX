"""Abstract base for every ArgusX agent node.

Each node is a class so it can hold its own dependencies (database, vector
store, model client) while still being callable by LangGraph. LangGraph invokes
a node as ``node(state) -> partial_state``; we satisfy that by making instances
callable via ``__call__`` which delegates to the async ``run`` method.
"""

from __future__ import annotations

from abc import ABC, abstractmethod

from graph.argusx_state import ArgusXState


class ArgusXBaseNode(ABC):
    """Common contract shared by all graph nodes."""

    #: Stable identifier used as the node's name inside the graph.
    name: str = "argusx_base_node"

    @abstractmethod
    async def run(self, state: ArgusXState) -> dict:
        """Process the incoming state and return the partial update to merge."""
        raise NotImplementedError

    async def __call__(self, state: ArgusXState) -> dict:
        """LangGraph entrypoint — delegates to ``run``."""
        return await self.run(state)
