from __future__ import annotations

import logging
from typing import Dict, List

try:
    import librosa
except ImportError:  # pragma: no cover - optional dependency
    librosa = None

logger = logging.getLogger(__name__)


def analyze_audio(local_path: str) -> Dict[str, object]:
    """Analyze the uploaded audio file for duration, BPM, and beat grid."""

    if librosa is None:
        logger.warning("librosa not available; returning stubbed audio analysis values")
        return {
            "duration_seconds": 0.0,
            "bpm": 120.0,
            "beat_grid": [i * 0.5 for i in range(16)],
        }

    y, sr = librosa.load(local_path)
    tempo, beats = librosa.beat.beat_track(y=y, sr=sr)
    beat_times: List[float] = librosa.frames_to_time(beats, sr=sr).tolist()
    duration = librosa.get_duration(y=y, sr=sr)

    return {
        "duration_seconds": float(duration),
        "bpm": float(tempo),
        "beat_grid": beat_times,
    }
