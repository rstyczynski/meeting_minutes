#!/usr/bin/env python3
"""Compare reference-speaker energy on two local AMI microphone tracks.

This is a diagnostic only: amplitude separation is not transcription quality.
Do not put meeting content or model output in Git.
"""

import argparse
import array
import json
import math
import statistics
import sys
import wave
from pathlib import Path


def load_samples(path: Path) -> tuple[int, array.array]:
    with wave.open(str(path), "rb") as audio:
        if audio.getnchannels() != 1 or audio.getsampwidth() != 2:
            raise ValueError(f"Expected 16-bit mono PCM WAV: {path}")
        samples = array.array("h")
        samples.frombytes(audio.readframes(audio.getnframes()))
        if sys.byteorder != "little":
            samples.byteswap()
        return audio.getframerate(), samples


def clean_windows(words: list[dict], target: str, duration: float = 0.1) -> list[float]:
    windows = []
    other = [(w["start_seconds"], w["end_seconds"]) for w in words if w["speaker"] != target]
    for word in words:
        if (word["speaker"] == target and
                word["end_seconds"] - word["start_seconds"] >= duration):
            midpoint = (word["start_seconds"] + word["end_seconds"]) / 2
            start, end = midpoint - duration / 2, midpoint + duration / 2
            if all(end <= left or start >= right for left, right in other):
                windows.append(midpoint)
    return windows


def median_rms(samples: array.array, rate: int, midpoints: list[float]) -> float:
    width = int(rate * 0.1)
    measurements = []
    for midpoint in midpoints:
        start = int(midpoint * rate) - width // 2
        end = start + width
        if start < 0 or end > len(samples):
            continue
        chunk = samples[start:end]
        measurements.append(math.sqrt(sum(value * value for value in chunk) / width) / 32768)
    if not measurements:
        raise ValueError("No valid measurement windows")
    return statistics.median(measurements)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--headset", required=True, type=Path)
    parser.add_argument("--lapel", required=True, type=Path)
    parser.add_argument("--speaker", default="B")
    args = parser.parse_args()

    words = json.loads(args.reference.read_text())["words"]
    target_windows = clean_windows(words, args.speaker)
    # The second set is rebuilt from words not spoken by the target.
    non_target_words = [
        {**word, "speaker": "__other__" if word["speaker"] != args.speaker else args.speaker}
        for word in words
    ]
    other_windows = clean_windows(non_target_words, "__other__")

    if not target_windows or not other_windows:
        parser.error("Reference does not provide isolated words for both groups")
    print(f"reference windows: {args.speaker}={len(target_windows)}, others={len(other_windows)}")

    for path in (args.headset, args.lapel):
        rate, samples = load_samples(path)
        target_rms = median_rms(samples, rate, target_windows)
        other_rms = median_rms(samples, rate, other_windows)
        ratio = target_rms / other_rms if other_rms else math.inf
        print(f"{path.name}: median {args.speaker} RMS={target_rms:.5f}; "
              f"other-speaker RMS={other_rms:.5f}; separation ratio={ratio:.2f}")


if __name__ == "__main__":
    main()
