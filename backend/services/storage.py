from __future__ import annotations

import shutil
import tempfile
from pathlib import Path
from typing import BinaryIO

from ..config import settings


def _resolve_destination(dest_path: str) -> Path:
    base_path = Path(settings.storage_base_path)
    full_path = base_path / dest_path
    full_path.parent.mkdir(parents=True, exist_ok=True)
    return full_path


def upload_file(file_obj: BinaryIO, dest_path: str) -> str:
    """Upload a file-like object to object storage."""

    destination = _resolve_destination(dest_path)
    with open(destination, "wb") as out_file:
        shutil.copyfileobj(file_obj, out_file)
    return dest_path


def upload_bytes(data: bytes, dest_path: str, content_type: str | None = None) -> str:
    """Upload raw bytes to object storage."""

    destination = _resolve_destination(dest_path)
    with open(destination, "wb") as out_file:
        out_file.write(data)
    return dest_path


def download_to_temp(path: str) -> str:
    """Download a file from storage to a temporary local file."""

    source_path = Path(settings.storage_base_path) / path
    if not source_path.exists():
        raise FileNotFoundError(f"Storage path does not exist: {path}")

    suffix = source_path.suffix
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
        with open(source_path, "rb") as in_file:
            shutil.copyfileobj(in_file, temp_file)
        temp_file_path = temp_file.name
    return temp_file_path
