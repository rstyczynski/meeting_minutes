#!/usr/bin/env python3
"""Score local ASR JSON against timed AMI words without printing meeting text.

The global WER is standard edit distance divided by reference token count.
Per-speaker figures attribute substitutions and deletions to reference words;
insertions are unassigned and speaker attribution is not assessed here.
"""

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path


def tokens(value: str) -> list[str]:
    return re.findall(r"[a-z0-9]+(?:'[a-z0-9]+)?", value.lower())


def hypothesis_segments(document: dict) -> list[tuple[float, float, str]]:
    if "transcription" in document:
        return [
            (entry["offsets"]["from"] / 1000, entry["offsets"]["to"] / 1000, entry["text"])
            for entry in document["transcription"]
        ]
    if "segments" in document:
        return [(entry["start"], entry["end"], entry["text"])
                for entry in document["segments"]]
    raise ValueError("Expected whisper.cpp transcription or FluidAudio segments")


def score(reference: list[tuple[str, str]], hypothesis: list[str]) -> dict:
    height, width = len(reference), len(hypothesis)
    prior = list(range(width + 1))
    operations = bytearray((height + 1) * (width + 1))
    for row in range(1, height + 1):
        current = [row] + [0] * width
        for column in range(1, width + 1):
            cost = 0 if reference[row - 1][0] == hypothesis[column - 1] else 1
            diagonal = prior[column - 1] + cost
            deletion = prior[column] + 1
            insertion = current[column - 1] + 1
            best = min(diagonal, deletion, insertion)
            current[column] = best
            operations[row * (width + 1) + column] = (
                0 if best == diagonal else 1 if best == deletion else 2
            )
        prior = current

    by_speaker = defaultdict(lambda: {"reference_words": 0, "substitutions": 0, "deletions": 0})
    for _, speaker in reference:
        by_speaker[speaker]["reference_words"] += 1

    substitutions = deletions = insertions = 0
    row, column = height, width
    while row or column:
        if row == 0:
            insertions += 1
            column -= 1
        elif column == 0:
            deletions += 1
            by_speaker[reference[row - 1][1]]["deletions"] += 1
            row -= 1
        else:
            operation = operations[row * (width + 1) + column]
            if operation == 0:
                if reference[row - 1][0] != hypothesis[column - 1]:
                    substitutions += 1
                    by_speaker[reference[row - 1][1]]["substitutions"] += 1
                row -= 1
                column -= 1
            elif operation == 1:
                deletions += 1
                by_speaker[reference[row - 1][1]]["deletions"] += 1
                row -= 1
            else:
                insertions += 1
                column -= 1

    for values in by_speaker.values():
        values["reference_linked_error_rate"] = round(
            (values["substitutions"] + values["deletions"]) / values["reference_words"], 4
        )
    return {
        "reference_words": height,
        "hypothesis_words": width,
        "substitutions": substitutions,
        "deletions": deletions,
        "insertions": insertions,
        "wer": round((substitutions + deletions + insertions) / height, 4),
        "reference_speakers": dict(sorted(by_speaker.items())),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--hypothesis", required=True, type=Path)
    parser.add_argument("--start-seconds", type=float)
    parser.add_argument("--end-seconds", type=float)
    args = parser.parse_args()

    words = json.loads(args.reference.read_text())["words"]
    start = args.start_seconds if args.start_seconds is not None else min(w["start_seconds"] for w in words)
    end = args.end_seconds if args.end_seconds is not None else max(w["end_seconds"] for w in words)
    if end <= start:
        parser.error("Scoring end must be after start")
    reference = [
        (token, word["speaker"])
        for word in words if word["start_seconds"] >= start and word["end_seconds"] <= end
        for token in tokens(word["text"])
    ]
    if not reference:
        parser.error("No reference words in selected time window")

    document = json.loads(args.hypothesis.read_text())
    hypothesis = [
        token
        for segment_start, segment_end, text in hypothesis_segments(document)
        if segment_end > start and segment_start < end
        for token in tokens(text)
    ]
    result = score(reference, hypothesis)
    result["window_seconds"] = [start, end]
    result["hypothesis_file"] = args.hypothesis.name
    result["limits"] = (
        "Segments crossing the window boundary are included whole. "
        "Per-speaker figures omit insertions and do not measure speaker attribution."
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
