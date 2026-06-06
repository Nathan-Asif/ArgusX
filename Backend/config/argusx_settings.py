"""Central configuration system for the ArgusX backend.

Every tunable value the orchestrator needs is funnelled through a single
``ArgusXSettings`` object so that the rest of the codebase never reads
environment variables directly. This keeps configuration testable and the
dependency direction clean (systems depend on settings, not on ``os.environ``).
"""

from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class ArgusXSettings(BaseSettings):
    """Typed, validated view over the ``.env`` file and process environment."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="ARGUSX_",
        extra="ignore",
        case_sensitive=False,
    )

    # --- Application identity ------------------------------------------------
    app_name: str = Field(default="ArgusX Orchestrator")
    environment: str = Field(default="development")
    debug: bool = Field(default=True)

    # --- HTTP server ---------------------------------------------------------
    host: str = Field(default="0.0.0.0")
    port: int = Field(default=8000)
    cors_origins: str = Field(default="*")

    # --- Supabase / PostgreSQL data layer -----------------------------------
    supabase_url: str = Field(default="")
    supabase_key: str = Field(default="")
    database_url: str = Field(default="")

    # --- Local FAISS vector store -------------------------------------------
    vector_index_path: str = Field(default="vector_store/faiss_index.bin")
    vector_dimension: int = Field(default=768)

    # --- Multimodal model (Gemini Live) -------------------------------------
    gemini_api_key: str = Field(default="")
    gemini_model: str = Field(default="gemini-3.1-flash-live")

    # --- Auth ----------------------------------------------------------------
    jwt_secret: str = Field(default="change-me")
    jwt_algorithm: str = Field(default="HS256")
    jwt_expiry_minutes: int = Field(default=60)

    @property
    def cors_origin_list(self) -> list[str]:
        """Split the comma-separated CORS origins into a usable list."""
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> ArgusXSettings:
    """Return a process-wide cached settings instance."""
    return ArgusXSettings()
