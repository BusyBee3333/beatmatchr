from __future__ import annotations

import logging
from typing import Dict, List

import moviepy.editor as mpe

logger = logging.getLogger(__name__)


def _parse_resolution(resolution: str) -> tuple[int, int]:
    try:
        width_str, height_str = resolution.lower().split("x")
        return int(width_str), int(height_str)
    except (ValueError, AttributeError) as exc:
        raise ValueError(f"Invalid resolution format: {resolution}") from exc


def render_video(
    audio_path: str,
    timeline: List[Dict],
    lyrics_timed_lines: List[Dict],
    output_path: str,
    resolution: str = "1080x1920",
    fps: int = 30,
) -> None:
    """Render the final video composition with lyrics overlays."""

    width, height = _parse_resolution(resolution)
    video_segments: List[mpe.VideoClip] = []

    try:
        for segment in timeline:
            clip_path = segment["clip_path"]
            video_start = float(segment.get("video_start", 0.0))
            video_end = float(segment.get("video_end")) if segment.get("video_end") is not None else None
            song_start = float(segment.get("song_start", 0.0))

            clip = mpe.VideoFileClip(clip_path)
            if video_end is not None:
                clip = clip.subclip(video_start, video_end)
            else:
                clip = clip.subclip(video_start)
            clip = clip.resize(newsize=(width, height)).set_start(song_start)
            video_segments.append(clip)

        if not video_segments:
            raise ValueError("Timeline is empty; cannot render video")

        base_video = mpe.concatenate_videoclips(video_segments, method="compose")

        text_clips: List[mpe.VideoClip] = []
        for line in lyrics_timed_lines:
            text = line.get("text", "").strip()
            if not text:
                continue
            start = float(line["start"])
            end = float(line["end"])
            duration = max(end - start, 0.1)
            text_clip = (
                mpe.TextClip(
                    txt=text,
                    fontsize=60,
                    color="white",
                    stroke_color="black",
                    stroke_width=2,
                    method="caption",
                    size=(width - 200, None),
                )
                .set_duration(duration)
                .set_start(start)
                .set_position(("center", height - 150))
            )
            text_clips.append(text_clip)

        composite = mpe.CompositeVideoClip([base_video, *text_clips], size=(width, height))
        audio_clip = mpe.AudioFileClip(audio_path)
        composite = composite.set_audio(audio_clip)
        composite.write_videofile(
            output_path,
            codec="libx264",
            audio_codec="aac",
            fps=fps,
            preset="medium",
        )
    finally:
        for clip in video_segments:
            clip.close()
        if "base_video" in locals():
            base_video.close()  # type: ignore[union-attr]
        if "text_clips" in locals():
            for clip in text_clips:
                clip.close()
        if "composite" in locals():
            composite.close()  # type: ignore[union-attr]
        if "audio_clip" in locals():
            audio_clip.close()  # type: ignore[union-attr]
