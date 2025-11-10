from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path
from typing import Optional

from pydantic import BaseSettings, Field


class Settings(BaseSettings):
    """Application configuration loaded from environment variables."""

    database_url: str = Field(
        default="sqlite+aiosqlite:///./beatmatchr.db",
        description="SQLAlchemy database URL",
    )
    sync_database_url: Optional[str] = Field(
        default="sqlite:///./beatmatchr.db",
        description="Optional sync URL for background workers",
    )
    storage_base_path: Path = Field(
        default=Path(os.getenv("BEATMATCHR_STORAGE", "./storage")),
        description="Base path for file storage when using local filesystem backend.",
    )
    celery_broker_url: str = Field(
        default=os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0"),
        description="Broker URL for Celery workers.",
    )
    celery_result_backend: str = Field(
        default=os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/0"),
        description="Result backend URL for Celery workers.",
    )
    transcription_api_url: Optional[str] = Field(
        default=os.getenv("TRANSCRIPTION_API_URL"),
        description="External transcription service endpoint.",
    )
    transcription_api_key: Optional[str] = Field(
        default=os.getenv("TRANSCRIPTION_API_KEY"),
        description="API key for transcription service if required.",
    )

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Return cached application settings instance."""

    settings = Settings()
    base_path = Path(settings.storage_base_path)
    base_path.mkdir(parents=True, exist_ok=True)
    return settings


settings = get_settings()
