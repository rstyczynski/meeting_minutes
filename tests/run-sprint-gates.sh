#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: tests/run-sprint-gates.sh progress/sprint_N [log-label]" >&2
  exit 2
fi

sprint_dir="$1"
label=""
if [[ $# -eq 2 ]]; then label="$2"; fi
if [[ ! "$sprint_dir" =~ ^progress/sprint_[0-9]+$ || ! -f "$sprint_dir/new_tests.manifest" ]]; then
  echo "Expected an active progress/sprint_N directory with new_tests.manifest" >&2
  exit 2
fi
if [[ -n "$label" && ! "$label" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Log label must use letters, numbers, underscore, or hyphen" >&2
  exit 2
fi

stamp="$(date '+%Y%m%d_%H%M%S')"
prefix="test_run_"
if [[ -n "$label" ]]; then prefix="$prefix$label"_ ; fi

run_gate() {
  local name="$1"
  shift
  local logfile="$sprint_dir/$prefix$name"_"$stamp.log"
  echo "Running $name; log: $logfile"
  {
    printf 'Started: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'Command: tests/run.sh'
    printf ' %q' "$@"
    printf '\n'
    tests/run.sh "$@"
    printf 'Finished: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  } > "$logfile" 2>&1 || {
    echo "$name failed; last log lines:" >&2
    tail -n 25 "$logfile" >&2
    exit 1
  }
  echo "$name passed"
}

run_gate A1_smoke --smoke --new-only "$sprint_dir/new_tests.manifest"
run_gate A2_unit --unit --new-only "$sprint_dir/new_tests.manifest"
run_gate A3_integration --integration --new-only "$sprint_dir/new_tests.manifest"
run_gate B1_smoke --smoke
run_gate B2_unit --unit
run_gate B3_integration --integration
echo "All six Sprint gates passed; log stamp: $stamp"
