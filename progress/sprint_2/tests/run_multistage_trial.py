#!/usr/bin/env python3
"""Re-run EXP-8 on the committed transcript records; never alter source records."""
import argparse
import json
import os
from pathlib import Path
import resource
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[3]
MODEL = ROOT / ".models/qwen3-30b-a3b-instruct-2507-4bit"
ADAPTER = ROOT / "experiments/MinutesAdapter/.build/release/meeting-mlx-minutes"
CLI = ROOT / ".build/debug/meeting-summarizer"
EVIDENCE = ROOT / "progress/sprint_2/tests/multistage_20261004"
CASES = {
    "ami": "4395B92A-60B8-4B8C-9A20-3AE37642FE92",
    "sejm": "5DC83D71-D1B0-4568-A66D-70F3B9A71D46",
}


def run(case: str) -> None:
    identifier = CASES[case]
    source = ROOT / "progress/sprint_2/tests" / f"{identifier}.json"
    case_dir = EVIDENCE / case
    case_dir.mkdir(parents=True, exist_ok=True)
    store = Path("/private/tmp") / f"meeting-multistage-{case}-20261004"
    store.mkdir(parents=True, exist_ok=True)
    data = json.loads(source.read_text())
    data["reviewItems"] = []
    data.pop("cleanedTranscript", None)
    data.pop("topics", None)
    data.pop("topicAssignments", None)
    (store / source.name).write_text(json.dumps(data, ensure_ascii=False, indent=2))
    settings = store / "settings.json"
    settings.write_text(json.dumps({"transcriber": "fluid",
                                    "mlxModelDirectory": str(MODEL),
                                    "mlxExecutable": str(ADAPTER)}))
    env = dict(os.environ, MEETING_MINUTES_DIAGNOSTICS_DIR=str(case_dir))
    common = ["--settings", str(settings), "--store", str(store)]
    inspect = subprocess.run([str(CLI), "inspect-cleanup", identifier, *common],
                             text=True, capture_output=True, env=env)
    (case_dir / "cleanup.json").write_text(inspect.stdout)
    (case_dir / "cleanup.log").write_text(inspect.stderr)
    if inspect.returncode:
        raise RuntimeError(f"cleanup inspection failed for {case}: {inspect.stderr}")
    before = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
    start = time.monotonic()
    result = subprocess.run([str(CLI), "summarize", identifier,
                             "--summarizer", "mlx", "--pipeline", "multi-stage", *common],
                            text=True, capture_output=True, env=env)
    elapsed = time.monotonic() - start
    after = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
    (case_dir / "run.log").write_text(result.stdout + result.stderr)
    shutil.copy2(store / source.name, case_dir / "record.json")
    (case_dir / "metrics.json").write_text(json.dumps({
        "case": case, "record_id": identifier, "exit_code": result.returncode,
        "elapsed_seconds": round(elapsed, 3),
        "maximum_child_rss_bytes": after,
        "previous_child_rss_bytes": before,
        "raw_segment_count": len(data["segments"]),
        "prompt_revision": "minutes-v4.1-multistage",
        "model": MODEL.name,
    }, indent=2))
    print(case, "exit", result.returncode, "elapsed", round(elapsed, 1), "seconds")
    print(result.stderr.strip())


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("case", choices=CASES)
    run(parser.parse_args().case)
