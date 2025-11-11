from __future__ import annotations

import logging

from fastapi import FastAPI

from .db import init_db
from .routers import audio, lyrics, media

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    app = FastAPI(title="Beatmatchr API", version="0.1.0")

    @app.on_event("startup")
    def _startup() -> None:  # pragma: no cover - FastAPI lifecycle
        init_db()
        logger.info("Database initialized")

    app.include_router(media.router, prefix="/api")
    app.include_router(audio.router, prefix="/api")
    app.include_router(lyrics.router, prefix="/api")

    @app.get("/health")
    async def healthcheck() -> dict:
        return {"status": "ok"}

    return app


app = create_app()
