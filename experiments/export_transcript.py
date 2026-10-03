#!/usr/bin/env python3
"""Render a saved MeetingCore record as a readable, timed transcript."""

import argparse
import json
import os
from pathlib import Path


def clock(seconds: float) -> str:
    minutes, remainder = divmod(seconds, 60)
    return f"{int(minutes):02d}:{remainder:05.2f}"


def render(source: Path, destination: Path, title: str) -> str:
    record = json.loads(source.read_text(encoding="utf-8"))
    segments = record["segments"]
    if not segments:
        raise ValueError(f"No transcript segments in {source}")

    language = record.get("processingParameters", {}).get("requestedLanguage", "unknown")
    source_link = os.path.relpath(source.resolve(), destination.parent.resolve())
    lines = [
        f"# {title}",
        "",
        f"Source record: [{source.name}]({source_link})",
        "",
        f"Record ID: `{record['id']}`. Language: `{language}`. "
        f"ASR model: `{record.get('modelRevision', 'unknown')}`. "
        f"Timed segments: {len(segments)}.",
        "",
        "This is the complete, uncorrected ASR output in the saved record. "
        "Speaker IDs are anonymous model assignments, not verified names. "
        "Lines combine consecutive stored segments for reading; the linked "
        "JSON preserves every segment and its exact time range.",
        "",
    ]

    group = []
    group_start = group_end = 0.0
    group_speaker = ""

    def flush() -> None:
        if group:
            lines.append(
                f"[{clock(group_start)}–{clock(group_end)}] "
                f"{group_speaker}: {' '.join(group)}"
            )
            lines.append("")

    for segment in segments:
        start = float(segment["range"]["startSeconds"])
        end = float(segment["range"]["endSeconds"])
        speaker = segment.get("speakerID") or "Unassigned"
        if group and (
            speaker != group_speaker
            or end - group_start > 10.0
            or start - group_end > 1.5
        ):
            flush()
            group = []
        if not group:
            group_start = start
            group_speaker = speaker
        group.append(segment["text"])
        group_end = end
    flush()
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="saved MeetingCore record JSON")
    parser.add_argument("destination", type=Path, help="output Markdown file")
    parser.add_argument("--title", required=True)
    args = parser.parse_args()
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    args.destination.write_text(
        render(args.source, args.destination, args.title), encoding="utf-8"
    )


if __name__ == "__main__":
    main()
