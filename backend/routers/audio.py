from __future__ import annotations

import uuid

from fastapi import APIRouter, File, HTTPException, UploadFile, status

from ..db import db_session
from ..models import AudioTrack, Project
from ..services import storage
from ..workers.tasks import task_analyze_audio, task_transcribe_lyrics

router = APIRouter(prefix="/projects/{project_id}/audio", tags=["audio"])


@router.post("", status_code=status.HTTP_201_CREATED)
async def upload_audio(project_id: str, file: UploadFile = File(...)) -> dict:
    if not file.content_type or not file.content_type.startswith("audio/"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Uploaded file must be audio")

    audio_id = str(uuid.uuid4())
    extension = "." + file.filename.split(".")[-1] if file.filename and "." in file.filename else ".mp3"
    storage_dest = f"audio/{project_id}/{audio_id}{extension}"
    storage_path = ""

    try:
        with db_session() as session:
            project = session.query(Project).filter_by(id=project_id).one_or_none()
            if project is None:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

            file.file.seek(0)
            storage_path = storage.upload_file(file.file, storage_dest)

            audio_track = AudioTrack(
                id=audio_id,
                project_id=project_id,
                storage_path=storage_path,
            )
            session.add(audio_track)
            session.commit()
    finally:
        file.file.close()

    if not storage_path:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to store audio file")

    task_analyze_audio.delay(audio_track_id=audio_id)
    task_transcribe_lyrics.delay(project_id=project_id, audio_track_id=audio_id)

    return {
        "audio_track_id": audio_id,
        "project_id": project_id,
        "storage_path": storage_path,
    }
