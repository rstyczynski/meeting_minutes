#!/usr/bin/env bash
set -euo pipefail

# SM-1: package and CLI build, with compatible import route.
swift build
help_text="$(swift run meeting-summarizer --help)"
[[ "$help_text" == *"import"* ]]
# SM-2: accepted independent CLI capabilities.
[[ "$help_text" == *"transcribe"* ]]
[[ "$help_text" == *"recognize"* ]]
[[ "$help_text" == *"summarize"* ]]
