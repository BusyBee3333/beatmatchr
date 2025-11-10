from __future__ import annotations

from fastapi import APIRouter, HTTPException

from ..db import db_session
from ..models import Lyrics, Project

router = APIRouter(prefix="/projects/{project_id}/lyrics", tags=["lyrics"])


@router.get("")
def get_lyrics(project_id: str) -> dict:
    with db_session() as session:
        project = session.query(Project).filter_by(id=project_id).one_or_none()
        if project is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

        lyrics = session.query(Lyrics).filter_by(project_id=project_id).one_or_none()
        if lyrics is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lyrics not found")

        return {
            "project_id": lyrics.project_id,
            "source": lyrics.source,
            "raw_text": lyrics.raw_text,
            "timed_lines": lyrics.timed_lines or [],
            "timed_words": lyrics.timed_words or [],
            "created_at": lyrics.created_at,
            "updated_at": lyrics.updated_at,
        }


@router.put("")
def update_lyrics(project_id: str, payload: dict) -> dict:
    new_text = payload.get("raw_text")
    if not isinstance(new_text, str) or not new_text.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="raw_text must be provided")

    with db_session() as session:
        project = session.query(Project).filter_by(id=project_id).one_or_none()
        if project is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

        lyrics = session.query(Lyrics).filter_by(project_id=project_id).one_or_none()
        if lyrics is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lyrics not found")

        lyrics.raw_text = new_text.strip()
        session.commit()

        return {
            "project_id": lyrics.project_id,
            "source": lyrics.source,
            "raw_text": lyrics.raw_text,
            "timed_lines": lyrics.timed_lines or [],
            "timed_words": lyrics.timed_words or [],
            "created_at": lyrics.created_at,
            "updated_at": lyrics.updated_at,
        }
