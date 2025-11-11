from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, JSON, String, Text, Integer
from sqlalchemy.orm import relationship

from .db import Base, db_session


class TimestampMixin:
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )


class Project(Base, TimestampMixin):
    __tablename__ = "projects"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)

    audio_tracks = relationship("AudioTrack", back_populates="project", cascade="all, delete-orphan")
    source_clips = relationship("SourceClip", back_populates="project", cascade="all, delete-orphan")
    lyrics = relationship("Lyrics", back_populates="project", uselist=False, cascade="all, delete-orphan")


class AudioTrack(Base, TimestampMixin):
    __tablename__ = "audio_tracks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    project_id = Column(String, ForeignKey("projects.id"), nullable=False, index=True)
    storage_path = Column(Text, nullable=False)
    local_path = Column(Text, nullable=True)
    duration_seconds = Column(Float, nullable=True)
    bpm = Column(Float, nullable=True)
    beat_grid = Column(JSON, nullable=True)

    project = relationship("Project", back_populates="audio_tracks")


class SourceClip(Base, TimestampMixin):
    __tablename__ = "source_clips"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    project_id = Column(String, ForeignKey("projects.id"), nullable=False, index=True)
    origin = Column(String, nullable=False)
    original_url = Column(Text, nullable=True)
    storage_path = Column(Text, nullable=False)
    thumbnail_path = Column(Text, nullable=True)
    duration_seconds = Column(Float, nullable=True)
    width = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)
    fps = Column(Float, nullable=True)

    project = relationship("Project", back_populates="source_clips")


class Lyrics(Base, TimestampMixin):
    __tablename__ = "lyrics"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    project_id = Column(String, ForeignKey("projects.id"), nullable=False, unique=True, index=True)
    source = Column(String, nullable=False)
    raw_text = Column(Text, nullable=False)
    timed_words = Column(JSON, nullable=True)
    timed_lines = Column(JSON, nullable=True)

    project = relationship("Project", back_populates="lyrics")


__all__ = [
    "Project",
    "AudioTrack",
    "SourceClip",
    "Lyrics",
    "db_session",
]
