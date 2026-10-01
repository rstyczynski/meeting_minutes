#!/usr/bin/env python3
"""Score diarizer turn coverage against timed AMI reference words.

This word-midpoint measure is not diarization error rate. It aligns anonymous
predicted labels to reference speakers by maximizing covered reference words.
"""

import argparse
from collections import Counter, defaultdict
from itertools import permutations
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--diarization", required=True, type=Path)
    args = parser.parse_args()

    words = json.loads(args.reference.read_text())["words"]
    document = json.loads(args.diarization.read_text())
    segments = document["segments"]
    warnings = document.get("warnings", [])
    labels = sorted({segment["speaker"] for segment in segments})
    speakers = sorted({word["speaker"] for word in words})
    if len(labels) > 8:
        parser.error("More than eight predicted labels need an assignment solver")

    active_by_word = []
    overlaps = Counter()
    for word in words:
        midpoint = (word["start_seconds"] + word["end_seconds"]) / 2
        active = {segment["speaker"] for segment in segments
                  if segment["start"] <= midpoint < segment["end"]}
        active_by_word.append(active)
        for label in active:
            overlaps[(label, word["speaker"])] += 1

    best_mapping = {}
    best_hits = -1
    # Assign distinct anonymous labels to distinct reference speakers.
    for candidate in permutations(speakers, len(labels)):
        mapping = dict(zip(labels, candidate))
        hits = sum(overlaps[(label, speaker)] for label, speaker in mapping.items())
        if hits > best_hits:
            best_hits, best_mapping = hits, mapping

    results = defaultdict(lambda: {"reference_words": 0, "correct": 0,
                                   "wrong": 0, "uncovered": 0, "multiple_labels": 0})
    for word, active in zip(words, active_by_word):
        item = results[word["speaker"]]
        item["reference_words"] += 1
        if not active:
            item["uncovered"] += 1
        elif word["speaker"] in {best_mapping[label] for label in active}:
            item["correct"] += 1
        else:
            item["wrong"] += 1
        if len(active) > 1:
            item["multiple_labels"] += 1

    total = Counter()
    for item in results.values():
        total.update(item)
    warning_by_speaker = defaultdict(lambda: {"reference_words": 0, "flagged": 0})
    for word in words:
        item = warning_by_speaker[word["speaker"]]
        item["reference_words"] += 1
        midpoint = (word["start_seconds"] + word["end_seconds"]) / 2
        if any(warning["start"] <= midpoint < warning["end"] for warning in warnings):
            item["flagged"] += 1
    print(json.dumps({
        "reference_file": args.reference.name,
        "diarization_file": args.diarization.name,
        "predicted_segments": len(segments),
        "predicted_speakers": len(labels),
        "reference_speakers": len(speakers),
        "best_label_mapping": best_mapping,
        "overall": dict(total),
        "by_reference_speaker": dict(sorted(results.items())),
        "warning_ranges": len(warnings),
        "warning_speakers": sorted({warning["speaker"] for warning in warnings}),
        "warning_word_coverage": dict(sorted(warning_by_speaker.items())),
        "limits": "Word-midpoint coverage with an optimal label mapping, not DER/JER; "
                  "multiple active labels receive credit if any matches; "
                  "unannotated speech and false alarms outside reference words are not scored.",
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
