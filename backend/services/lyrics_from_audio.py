from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

import requests

from ..config import settings

logger = logging.getLogger(__name__)


@dataclass
class TranscriptionResult:
    raw_text: str
    words: List[Dict[str, Any]]


class TranscriptionClient:
    """Client for an external transcription API that returns word timestamps."""

    def __init__(
        self,
        api_url: Optional[str] = None,
        api_key: Optional[str] = None,
        timeout: int = 300,
    ) -> None:
        self.api_url = api_url or settings.transcription_api_url
        self.api_key = api_key or settings.transcription_api_key
        self.timeout = timeout

    def transcribe(self, audio_path: str) -> TranscriptionResult:
        if not self.api_url:
            raise RuntimeError(
                "Transcription API URL is not configured. Set TRANSCRIPTION_API_URL to enable lyrics extraction."
            )

        file_path = Path(audio_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        headers = {}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"

        with file_path.open("rb") as audio_file:
            files = {"file": (file_path.name, audio_file, "application/octet-stream")}
            data = {"timestamps": "word"}
            response = requests.post(
                self.api_url,
                headers=headers,
                data=data,
                files=files,
                timeout=self.timeout,
            )
        response.raise_for_status()

        payload = response.json()
        raw_text = payload.get("text") or payload.get("raw_text")
        if raw_text is None:
            raise ValueError("Transcription response missing 'text' field")

        words = payload.get("words") or []
        normalized_words: List[Dict[str, Any]] = []
        for word in words:
            try:
                normalized_words.append(
                    {
                        "start": float(word["start"]),
                        "end": float(word["end"]),
                        "word": str(word.get("word") or word.get("text") or "").strip(),
                    }
                )
            except (KeyError, TypeError, ValueError) as exc:
                logger.warning("Skipping malformed word entry %s: %s", word, exc)
        return TranscriptionResult(raw_text=raw_text.strip(), words=normalized_words)


def words_to_lines(words: List[Dict[str, Any]], max_silence_gap: float = 0.7) -> List[Dict[str, Any]]:
    """Group word-level timestamps into line-level segments."""

    if not words:
        return []

    sorted_words = sorted(words, key=lambda w: w["start"])
    lines: List[Dict[str, Any]] = []
    current_line_words: List[Dict[str, Any]] = [sorted_words[0]]

    for previous_word, current_word in zip(sorted_words, sorted_words[1:]):
        gap = float(current_word["start"]) - float(previous_word["end"])
        if gap > max_silence_gap:
            lines.append(
                {
                    "start": float(current_line_words[0]["start"]),
                    "end": float(current_line_words[-1]["end"]),
                    "text": " ".join(word["word"] for word in current_line_words).strip(),
                }
            )
            current_line_words = [current_word]
        else:
            current_line_words.append(current_word)

    if current_line_words:
        lines.append(
            {
                "start": float(current_line_words[0]["start"]),
                "end": float(current_line_words[-1]["end"]),
                "text": " ".join(word["word"] for word in current_line_words).strip(),
            }
        )

    return lines


def transcribe_audio_to_lyrics(local_audio_path: str) -> Dict[str, Any]:
    """Transcribe the uploaded audio file into lyrics with timing information."""

    client = TranscriptionClient()
    result = client.transcribe(local_audio_path)
    lines = words_to_lines(result.words)

    return {
        "raw_text": result.raw_text,
        "words": result.words,
        "lines": lines,
    }
