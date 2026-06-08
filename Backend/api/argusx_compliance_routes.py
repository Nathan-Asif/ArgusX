"""Proxy routes for Java compliance menu-config queries."""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel, Field

from services.argusx_compliance_client import ArgusXComplianceClient


class ArgusXMenuConfigRequest(BaseModel):
    rider_id: str = Field(default="test-rider")
    request_type: str = Field(default="HUD_MENU_CONFIG")


class ArgusXComplianceRoutes:
    """Exposes compliance helpers to the Flutter/Web settings pages."""

    def __init__(self, compliance_client: ArgusXComplianceClient) -> None:
        self._compliance_client = compliance_client
        self.router = APIRouter(prefix="/compliance", tags=["compliance"])
        self._register()

    def _register(self) -> None:
        @self.router.post("/menu-config")
        async def menu_config(body: ArgusXMenuConfigRequest) -> dict:
            return await self._compliance_client.fetch_menu_config(body.rider_id)

        @self.router.get("/status")
        async def compliance_status() -> dict:
            return await self._compliance_client.health_check()
