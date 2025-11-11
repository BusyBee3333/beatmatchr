from __future__ import annotations

import json
import logging
import os
import subprocess
import tempfile
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, List

import requests
from PIL import Image

from ..db import db_session
from ..models import Project, SourceClip
from . import storage

logger = logging.getLogger(__name__)


def resolve_media_urls_from_input(url: str) -> List[str]:
    """Resolve direct media URLs for a given user-provided URL using yt-dlp."""

    try:
        process = subprocess.run(
            [
                "yt-dlp",
                "--dump-json",
                "--skip-download",
                url,
            ],
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        logger.warning("yt-dlp not installed; returning provided URL directly")
        return [url]

    if process.returncode != 0:
        logger.error("yt-dlp failed for %s: %s", url, process.stderr.strip())
        return [url]

    media_urls: List[str] = []
    for line in process.stdout.strip().splitlines():
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            continue
        url_field = payload.get("url") or payload.get("webpage_url")
        if url_field:
            media_urls.append(url_field)
    if not media_urls:
        media_urls.append(url)
    return media_urls


def download_media_file(media_url: str) -> str:
    """Download a media file to a temporary local path and return it."""

    response = requests.get(media_url, stream=True, timeout=60)
    response.raise_for_status()

    suffix = Path(media_url).suffix or ".mp4"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                temp_file.write(chunk)
        temp_path = temp_file.name
    return temp_path


def extract_video_metadata(local_path: str) -> Dict[str, float | int | None]:
    """Extract video metadata using ffprobe."""

    command = [
        "ffprobe",
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=width,height,r_frame_rate:format=duration",
        "-of",
        "json",
        local_path,
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"ffprobe failed: {result.stderr}")

    payload = json.loads(result.stdout)
    stream = (payload.get("streams") or [{}])[0]
    format_info = payload.get("format") or {}

    r_frame_rate = stream.get("r_frame_rate", "0/1")
    try:
        num, den = r_frame_rate.split("/")
        fps = float(num) / float(den) if float(den) else None
    except (ValueError, ZeroDivisionError):
        fps = None

    metadata = {
        "duration_seconds": float(format_info.get("duration")) if format_info.get("duration") else None,
        "width": stream.get("width"),
        "height": stream.get("height"),
        "fps": fps,
    }
    return metadata


def generate_thumbnail(local_video_path: str, time_seconds: float = 0.5) -> bytes:
    """Generate a thumbnail image for a video clip using ffmpeg."""

    resized_path: str | None = None
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_image:
        temp_image_path = temp_image.name

    try:
        command = [
            "ffmpeg",
            "-ss",
            str(time_seconds),
            "-i",
            local_video_path,
            "-frames:v",
            "1",
            "-q:v",
            "2",
            temp_image_path,
        ]
        result = subprocess.run(command, capture_output=True, check=False)
        if result.returncode != 0:
            raise RuntimeError(f"ffmpeg thumbnail generation failed: {result.stderr}")

        with Image.open(temp_image_path) as img:
            width = 480
            ratio = width / float(img.width)
            resized = img.resize((width, int(img.height * ratio)))
            with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as resized_file:
                resized.save(resized_file.name, format="JPEG", quality=90)
                resized_path = resized_file.name
        if resized_path is None:
            raise RuntimeError("Failed to create thumbnail image")
        with open(resized_path, "rb") as thumbnail_file:
            data = thumbnail_file.read()
    finally:
        if os.path.exists(temp_image_path):
            os.remove(temp_image_path)
        if resized_path and os.path.exists(resized_path):
            os.remove(resized_path)
    return data


def ingest_single_media_url(project_id: str, input_url: str, origin: str = "url") -> List[Dict]:
    """Ingest media from a URL and persist SourceClip entries."""

    media_urls = resolve_media_urls_from_input(input_url)
    created_clips: List[Dict] = []

    with db_session() as session:
        project = session.query(Project).filter_by(id=project_id).one_or_none()
        if project is None:
            raise ValueError(f"Project {project_id} does not exist")

        for media_url in media_urls:
            local_path = download_media_file(media_url)
            try:
                metadata = extract_video_metadata(local_path)
                thumbnail_bytes = generate_thumbnail(local_path)

                clip_id = str(uuid.uuid4())
                extension = Path(local_path).suffix or ".mp4"
                storage_dest = f"videos/{project_id}/{clip_id}{extension}"
                thumb_dest = f"thumbnails/{project_id}/{clip_id}.jpg"

                with open(local_path, "rb") as infile:
                    storage_path = storage.upload_file(infile, storage_dest)
                thumbnail_path = storage.upload_bytes(thumbnail_bytes, thumb_dest, content_type="image/jpeg")

                now = datetime.utcnow()
                clip = SourceClip(
                    id=clip_id,
                    project_id=project_id,
                    origin=origin,
                    original_url=input_url,
                    storage_path=storage_path,
                    thumbnail_path=thumbnail_path,
                    duration_seconds=metadata.get("duration_seconds"),
                    width=metadata.get("width"),
                    height=metadata.get("height"),
                    fps=metadata.get("fps"),
                    created_at=now,
                    updated_at=now,
                )
                session.add(clip)
                session.flush()

                created_clips.append(
                    {
                        "id": clip.id,
                        "project_id": clip.project_id,
                        "storage_path": clip.storage_path,
                        "thumbnail_path": clip.thumbnail_path,
                        "duration_seconds": clip.duration_seconds,
                        "width": clip.width,
                        "height": clip.height,
                        "fps": clip.fps,
                        "origin": clip.origin,
                        "original_url": clip.original_url,
                    }
                )
            finally:
                if os.path.exists(local_path):
                    os.remove(local_path)
        session.commit()

    return created_clips
