#!/usr/bin/env bash
set -euo pipefail

# SM-1: fails until the approved Swift package and CLI are built.
swift build
help_text="$(swift run meeting-summarizer --help)"
[[ "$help_text" == *"import"* ]]
