from __future__ import annotations

import os
import uuid
from datetime import datetime

from celery import Celery

from ..config import settings
from ..db import db_session
from ..models import AudioTrack, Lyrics, SourceClip
from ..services import audio_analysis, lyrics_from_audio, media_ingest, storage

celery_app = Celery(
    "beatmatchr",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
)


@celery_app.task(name="media.ingest_url")
def task_ingest_url(project_id: str, input_url: str, origin: str = "url") -> None:
    """Ingest media from a URL for the specified project."""

    media_ingest.ingest_single_media_url(project_id=project_id, input_url=input_url, origin=origin)


@celery_app.task(name="media.process_uploaded_video")
def task_process_uploaded_video(source_clip_id: str) -> None:
    """Extract metadata and thumbnails for an uploaded video clip."""

    with db_session() as session:
        clip = session.query(SourceClip).filter_by(id=source_clip_id).one()
        local_video = storage.download_to_temp(clip.storage_path)
        try:
            meta = media_ingest.extract_video_metadata(local_video)
            thumb_bytes = media_ingest.generate_thumbnail(local_video, time_seconds=0.5)

            thumb_dest = f"thumbnails/{clip.project_id}/{clip.id}.jpg"
            thumb_path = storage.upload_bytes(thumb_bytes, thumb_dest, content_type="image/jpeg")

            clip.duration_seconds = meta.get("duration_seconds")
            clip.width = meta.get("width")
            clip.height = meta.get("height")
            clip.fps = meta.get("fps")
            clip.thumbnail_path = thumb_path
            clip.updated_at = datetime.utcnow()

            session.commit()
        finally:
            if os.path.exists(local_video):
                os.remove(local_video)


@celery_app.task(name="audio.analyze")
def task_analyze_audio(audio_track_id: str) -> None:
    """Analyze audio track to compute BPM and beat grid."""

    with db_session() as session:
        audio = session.query(AudioTrack).filter_by(id=audio_track_id).one()
        local_path = storage.download_to_temp(audio.storage_path)
        try:
            result = audio_analysis.analyze_audio(local_path)

            audio.duration_seconds = result.get("duration_seconds")
            audio.bpm = result.get("bpm")
            audio.beat_grid = result.get("beat_grid")
            audio.updated_at = datetime.utcnow()

            session.commit()
        finally:
            if os.path.exists(local_path):
                os.remove(local_path)


@celery_app.task(name="lyrics.transcribe")
def task_transcribe_lyrics(project_id: str, audio_track_id: str) -> None:
    """Transcribe lyrics from the project's audio track."""

    with db_session() as session:
        audio = session.query(AudioTrack).filter_by(id=audio_track_id).one()
        local_path = storage.download_to_temp(audio.storage_path)
        try:
            result = lyrics_from_audio.transcribe_audio_to_lyrics(local_path)
            raw_text = result["raw_text"]
            words = result.get("words", [])
            lines = result.get("lines", [])

            existing = session.query(Lyrics).filter_by(project_id=project_id).one_or_none()
            now = datetime.utcnow()

            if existing is None:
                lyrics = Lyrics(
                    id=str(uuid.uuid4()),
                    project_id=project_id,
                    source="audio_transcription",
                    raw_text=raw_text,
                    timed_words=words,
                    timed_lines=lines,
                    created_at=now,
                    updated_at=now,
                )
                session.add(lyrics)
            else:
                existing.source = "audio_transcription"
                existing.raw_text = raw_text
                existing.timed_words = words
                existing.timed_lines = lines
                existing.updated_at = now

            session.commit()
        finally:
            if os.path.exists(local_path):
                os.remove(local_path)
