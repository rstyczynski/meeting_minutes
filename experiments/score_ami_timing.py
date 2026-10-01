#!/usr/bin/env python3
"""Compare ASR segment boundaries with aligned AMI manual word envelopes.

Only exact token matches contribute to a segment's reference envelope. This
is a diagnostic, not a full forced-alignment or timestamp-error benchmark.
"""

import argparse
from collections import defaultdict
import json
from pathlib import Path
from statistics import median

from score_ami_transcript import hypothesis_segments, tokens


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, int(fraction * (len(ordered) - 1)))]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--hypothesis", type=Path, required=True)
    args = parser.parse_args()

    words = json.loads(args.reference.read_text())["words"]
    start = min(word["start_seconds"] for word in words)
    end = max(word["end_seconds"] for word in words)
    reference = [(token, word["start_seconds"], word["end_seconds"])
                 for word in words for token in tokens(word["text"])]
    all_segments = hypothesis_segments(json.loads(args.hypothesis.read_text()))
    selected = [(i, a, b, text) for i, (a, b, text) in enumerate(all_segments)
                if a >= start and b <= end and b > a]
    hypothesis = [(token, i) for i, _, _, text in selected for token in tokens(text)]

    height, width = len(reference), len(hypothesis)
    prior = list(range(width + 1))
    operations = bytearray((height + 1) * (width + 1))
    for row in range(1, height + 1):
        current = [row] + [0] * width
        for column in range(1, width + 1):
            cost = reference[row - 1][0] != hypothesis[column - 1][0]
            diagonal = prior[column - 1] + cost
            deletion = prior[column] + 1
            insertion = current[column - 1] + 1
            best = min(diagonal, deletion, insertion)
            current[column] = best
            operations[row * (width + 1) + column] = (
                0 if best == diagonal else 1 if best == deletion else 2)
        prior = current

    matched = defaultdict(list)
    row, column = height, width
    while row and column:
        operation = operations[row * (width + 1) + column]
        if operation == 0:
            if reference[row - 1][0] == hypothesis[column - 1][0]:
                matched[hypothesis[column - 1][1]].append(reference[row - 1])
            row -= 1
            column -= 1
        elif operation == 1:
            row -= 1
        else:
            column -= 1

    start_errors = []
    end_errors = []
    matched_tokens = 0
    for segment_index, segment_start, segment_end, _ in selected:
        aligned = matched.get(segment_index, [])
        if not aligned:
            continue
        matched_tokens += len(aligned)
        start_errors.append(abs(segment_start - min(item[1] for item in aligned)))
        end_errors.append(abs(segment_end - max(item[2] for item in aligned)))
    if not start_errors:
        parser.error("No exactly matched reference tokens in complete segments")
    print(json.dumps({
        "reference_tokens": height,
        "hypothesis_tokens_in_complete_segments": width,
        "matched_tokens": matched_tokens,
        "complete_segments": len(selected),
        "segments_with_exact_match": len(start_errors),
        "median_absolute_start_error_seconds": round(median(start_errors), 3),
        "p90_absolute_start_error_seconds": round(percentile(start_errors, 0.9), 3),
        "median_absolute_end_error_seconds": round(median(end_errors), 3),
        "p90_absolute_end_error_seconds": round(percentile(end_errors, 0.9), 3),
        "limits": "Only complete segments in the annotation window with exact matched tokens; "
                  "reference envelope is formed from matched words, not segment ground truth; "
                  "word-level and multiword segment sizes differ across engines.",
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
