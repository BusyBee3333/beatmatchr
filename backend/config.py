"""Application configuration utilities."""
from __future__ import annotations

import os
from functools import lru_cache
from typing import Any, Dict


class Settings:
    """Configuration values loaded from environment variables.

    The defaults are tuned for local development and match the docker-compose
    configuration provided in this repository. Each value can be overridden by
    setting the corresponding environment variable before starting the
    application.
    """

    def __init__(self) -> None:
        self.postgres_user: str = os.getenv("POSTGRES_USER", "beatmatchr")
        self.postgres_password: str = os.getenv("POSTGRES_PASSWORD", "beatmatchr")
        self.postgres_db: str = os.getenv("POSTGRES_DB", "beatmatchr")
        self.postgres_host: str = os.getenv("POSTGRES_HOST", "localhost")
        self.postgres_port: int = int(os.getenv("POSTGRES_PORT", "5432"))

        self.redis_host: str = os.getenv("REDIS_HOST", "localhost")
        self.redis_port: int = int(os.getenv("REDIS_PORT", "6379"))
        self.redis_db: int = int(os.getenv("REDIS_DB", "0"))

        self.database_url: str = os.getenv(
            "DATABASE_URL",
            (
                "postgresql+asyncpg://"
                f"{self.postgres_user}:{self.postgres_password}"
                f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
            ),
        )

        redis_base_url = f"redis://{self.redis_host}:{self.redis_port}/{self.redis_db}"
        self.redis_url: str = os.getenv("REDIS_URL", redis_base_url)
        self.celery_broker_url: str = os.getenv("CELERY_BROKER_URL", self.redis_url)
        self.celery_result_backend: str = os.getenv(
            "CELERY_RESULT_BACKEND", self.redis_url
        )

    def dict(self) -> Dict[str, Any]:
        """Return the settings as a plain dictionary (useful for debugging)."""

        return {
            "postgres_user": self.postgres_user,
            "postgres_password": self.postgres_password,
            "postgres_db": self.postgres_db,
            "postgres_host": self.postgres_host,
            "postgres_port": self.postgres_port,
            "database_url": self.database_url,
            "redis_host": self.redis_host,
            "redis_port": self.redis_port,
            "redis_db": self.redis_db,
            "redis_url": self.redis_url,
            "celery_broker_url": self.celery_broker_url,
            "celery_result_backend": self.celery_result_backend,
        }
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
    """Return a cached instance of :class:`Settings`."""

    return Settings()
    """Return cached application settings instance."""

    settings = Settings()
    base_path = Path(settings.storage_base_path)
    base_path.mkdir(parents=True, exist_ok=True)
    return settings


settings = get_settings()
