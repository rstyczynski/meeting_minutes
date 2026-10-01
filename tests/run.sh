#!/usr/bin/env bash
set -u

level="${1:-}"
case "$level" in
  --smoke) suite=smoke ;;
  --unit) suite=unit ;;
  --integration) suite=integration ;;
  *) echo "Usage: tests/run.sh --smoke|--unit|--integration [--new-only MANIFEST]" >&2; exit 2 ;;
esac
shift

failures=0
if [[ "${1:-}" == "--new-only" ]]; then
  manifest="${2:-}"
  if [[ ! -f "$manifest" ]]; then
    echo "Missing new-tests manifest: $manifest" >&2
    exit 2
  fi
  while IFS=: read -r entry_suite script function; do
    [[ -z "$entry_suite" || "$entry_suite" == \#* || "$entry_suite" != "$suite" ]] && continue
    if [[ ! "$script" =~ ^[A-Za-z0-9_-]+\.sh$ ]]; then
      echo "Invalid test script: $script" >&2
      failures=$((failures + 1))
      continue
    fi
    bash "tests/$suite/$script" "${function:-}" || failures=$((failures + 1))
  done < "$manifest"
elif [[ $# -eq 0 ]]; then
  for script in tests/"$suite"/*.sh; do
    [[ -f "$script" ]] || continue
    bash "$script" || failures=$((failures + 1))
  done
else
  echo "Unknown option: $1" >&2
  exit 2
fi

if [[ $failures -ne 0 ]]; then
  echo "$suite: $failures failed test script(s)" >&2
  exit 1
fi
echo "$suite: all available test scripts passed"
