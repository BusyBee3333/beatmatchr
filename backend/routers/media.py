from __future__ import annotations

import uuid
from typing import List

from fastapi import APIRouter, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from ..db import db_session
from ..models import Project, SourceClip
from ..services import storage
from ..workers.tasks import task_ingest_url, task_process_uploaded_video

router = APIRouter(prefix="/projects/{project_id}/source-clips", tags=["source-clips"])


def get_project(session: Session, project_id: str) -> Project:
    project = session.query(Project).filter_by(id=project_id).one_or_none()
    if project is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return project


@router.post("/urls")
def enqueue_url_ingest(project_id: str, payload: dict) -> dict:
    urls = payload.get("urls") or []
    if not isinstance(urls, list) or not urls:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="urls must be a non-empty list")
    origin = payload.get("origin") or "url"

    for value in urls:
        if not isinstance(value, str) or not value.strip():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="All URLs must be non-empty strings")

    with db_session() as session:
        get_project(session, project_id)

    for url in urls:
        task_ingest_url.delay(project_id=project_id, input_url=url, origin=origin)

    return {"status": "queued", "count": len(urls)}


@router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_source_clip(project_id: str, file: UploadFile = File(...)) -> dict:
    if not file.content_type or not file.content_type.startswith("video/"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Uploaded file must be a video")

    clip_id = str(uuid.uuid4())
    extension = "." + file.filename.split(".")[-1] if file.filename and "." in file.filename else ".mp4"
    storage_dest = f"videos/{project_id}/{clip_id}{extension}"
    storage_path = ""

    try:
        with db_session() as session:
            get_project(session, project_id)

            file.file.seek(0)
            storage_path = storage.upload_file(file.file, storage_dest)

            clip = SourceClip(
                id=clip_id,
                project_id=project_id,
                origin="upload",
                original_url=None,
                storage_path=storage_path,
            )
            session.add(clip)
            session.commit()
    finally:
        file.file.close()

    if not storage_path:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to store uploaded file")

    task_process_uploaded_video.delay(source_clip_id=clip_id)

    return {
        "id": clip_id,
        "project_id": project_id,
        "storage_path": storage_path,
        "origin": "upload",
        "status": "processing",
    }


@router.get("")
def list_source_clips(project_id: str) -> List[dict]:
    with db_session() as session:
        get_project(session, project_id)
        clips = session.query(SourceClip).filter_by(project_id=project_id).order_by(SourceClip.created_at.asc()).all()

        return [
            {
                "id": clip.id,
                "origin": clip.origin,
                "original_url": clip.original_url,
                "storage_path": clip.storage_path,
                "thumbnail_path": clip.thumbnail_path,
                "duration_seconds": clip.duration_seconds,
                "width": clip.width,
                "height": clip.height,
                "fps": clip.fps,
                "created_at": clip.created_at,
                "updated_at": clip.updated_at,
            }
            for clip in clips
        ]
