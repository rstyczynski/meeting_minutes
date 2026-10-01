#!/usr/bin/env python3
"""Run the product CLI on a pinned FLEURS subset and score Unicode WER/CER."""

import argparse
import hashlib
import json
import re
import subprocess
import time
import unicodedata
from pathlib import Path


def normalized(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).casefold()
    return " ".join(re.findall(r"[^\W_]+", value, flags=re.UNICODE))


def distance(left: list[str], right: list[str]) -> int:
    previous = list(range(len(right) + 1))
    for row, item in enumerate(left, 1):
        current = [row]
        for column, other in enumerate(right, 1):
            current.append(min(previous[column] + 1, current[-1] + 1,
                               previous[column - 1] + (item != other)))
        previous = current
    return previous[-1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--cli", type=Path, default=Path(".build/debug/meeting-summarizer"))
    parser.add_argument("--fluid-model-dir", type=Path, required=True)
    parser.add_argument("--fluid-executable", type=Path, required=True)
    parser.add_argument("--whisper-model", type=Path, required=True)
    parser.add_argument("--whisper-executable", type=Path, required=True)
    parser.add_argument("--backend", choices=["fluid", "whisper", "both"], default="both")
    parser.add_argument("--requested-language", choices=["en", "pl", "auto"])
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(args.manifest.read_text())
    configurations = {
        "fluid": {"fluidModelDirectory": str(args.fluid_model_dir.resolve()),
                  "fluidModelVersion": "v3", "fluidExecutable": str(args.fluid_executable.resolve()),
                  "transcriber": "fluid"},
        "whisper": {"whisperModelPath": str(args.whisper_model.resolve()),
                    "whisperExecutable": str(args.whisper_executable.resolve()),
                    "whisperUseGPU": False,
                    "transcriber": "whisper"},
    }
    results = []
    for backend, settings in configurations.items():
        if args.backend != "both" and backend != args.backend:
            continue
        settings_file = output / f"settings_{backend}.json"
        settings_file.write_text(json.dumps(settings, indent=2) + "\n")
        for clip in manifest["clips"]:
            source = args.manifest.parent / clip["file"]
            actual_hash = hashlib.sha256(source.read_bytes()).hexdigest()
            if actual_hash != clip["sha256"]:
                raise ValueError(f"clip checksum mismatch: {source}")
            command = [str(args.cli.resolve()), "transcribe", str(source), "--transcriber", backend,
                       "--language", args.requested_language or clip["language"],
                       "--settings", str(settings_file),
                       "--store", str(output / "records")]
            start = time.monotonic()
            process = subprocess.run(command, capture_output=True, text=True)
            elapsed = round(time.monotonic() - start, 3)
            result = {"backend": backend, "clip": clip["file"], "language": clip["language"],
                      "sha256": clip["sha256"], "reference": clip["raw_reference"],
                      "seconds": elapsed, "exit_code": process.returncode}
            if process.returncode:
                result["error"] = process.stderr.strip()[:1000]
            else:
                record_id = process.stdout.strip().splitlines()[-1]
                record_file = output / "records" / (record_id + ".json")
                record = json.loads(record_file.read_text())
                hypothesis = " ".join(segment["text"] for segment in record["segments"])
                reference_words = normalized(clip["raw_reference"]).split()
                hypothesis_words = normalized(hypothesis).split()
                reference_chars = list("".join(reference_words))
                hypothesis_chars = list("".join(hypothesis_words))
                result.update(record_id=record_id, hypothesis=hypothesis,
                              model_revision=record["modelRevision"],
                              requested_language=record["processingParameters"].get("requestedLanguage"),
                              reference_words=len(reference_words),
                              word_errors=distance(reference_words, hypothesis_words),
                              reference_chars=len(reference_chars),
                              char_errors=distance(reference_chars, hypothesis_chars))
                result["wer"] = round(result["word_errors"] / len(reference_words), 4)
                result["cer"] = round(result["char_errors"] / len(reference_chars), 4)
            results.append(result)
            print(json.dumps(result, ensure_ascii=False), flush=True)
            (output / "results.json").write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
