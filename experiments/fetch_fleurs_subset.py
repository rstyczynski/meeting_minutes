#!/usr/bin/env python3
"""Stage a small, pinned FLEURS validation subset outside Git for FR-11."""

import argparse
import hashlib
import json
import time
from pathlib import Path
from urllib.request import urlopen


def fetch(url: str) -> bytes:
    for attempt in range(5):
        try:
            with urlopen(url, timeout=120) as response:
                data = response.read(10_000_001)
            if len(data) > 10_000_000:
                raise ValueError(f"unexpectedly large response: {url}")
            return data
        except (OSError, TimeoutError):
            if attempt == 4:
                raise
            time.sleep(2 ** attempt)
    raise RuntimeError("unreachable")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--count", default=5, type=int)
    args = parser.parse_args()
    if not 1 <= args.count <= 20:
        parser.error("count must be between 1 and 20")
    args.output.mkdir(parents=True, exist_ok=True)

    records = []
    for language, config in (("en", "en_us"), ("pl", "pl_pl")):
        api = (
            "https://datasets-server.huggingface.co/rows?dataset=google/fleurs"
            f"&config={config}&split=validation&offset=0&length={args.count}"
        )
        payload = json.loads(fetch(api))
        if len(payload["rows"]) != args.count:
            raise ValueError(f"expected {args.count} rows for {config}")
        for entry in payload["rows"]:
            row = entry["row"]
            audio_url = row["audio"][0]["src"]
            filename = f"{config}_{entry['row_idx']:04d}.wav"
            output = args.output / filename
            data = output.read_bytes() if output.exists() else fetch(audio_url)
            if data[:4] != b"RIFF":
                raise ValueError(f"expected WAV for {config} row {entry['row_idx']}")
            if not output.exists():
                output.write_bytes(data)
            records.append(
                {
                    "language": language,
                    "config": config,
                    "split": "validation",
                    "row_index": entry["row_idx"],
                    "clip_id": row["id"],
                    "speaker_id": row.get("speaker_id"),
                    "gender": row.get("gender"),
                    "file": filename,
                    "reference": row["transcription"],
                    "raw_reference": row["raw_transcription"],
                    "sha256": hashlib.sha256(data).hexdigest(),
                    "bytes": len(data),
                    "dataset_revision": audio_url.split("/--/")[1],
                    "source": api,
                }
            )

    manifest = args.output / "manifest.json"
    manifest.write_text(json.dumps({"license": "CC-BY-4.0", "clips": records},
                                   ensure_ascii=False, indent=2) + "\n")
    print(f"Staged {len(records)} clips in {args.output}; manifest: {manifest}")


if __name__ == "__main__":
    main()
