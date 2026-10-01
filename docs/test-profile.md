# Project test profile

Status: Accepted Sprint 1 test profile; Sprint 2 commands reconciled

## Purpose

This document maps the RUP test levels to Meeting Summarizer's actual build,
test, and operational-validation commands. PBI-009 established the profile
before Sprint 2. The active sprint uses the checked-in `tests/run.sh` runner
and its `new_tests.manifest`; the formal six-gate execution is still pending.
The Product Owner chose the open-source Swift Testing package because Apple
Command Line Tools on this Mac do not provide an importable XCTest module.

## Required Sprint 2 settings

Sprint 2 requires `Test: smoke, unit, integration` and `Regression: smoke,
unit, integration`.

## Current commands

Run these commands from the repository root. The runner accepts `--new-only
progress/sprint_2/new_tests.manifest` for the Sprint 2 new-work gates and
runs its full suite without that option for regression. The manager records
each formal gate in a timestamped log under `progress/sprint_2/`.

### Build

Command: `swift build`

Expected result: The `MeetingCore` library and `meeting-summarizer` executable
compile successfully. Package resolution may fetch source dependencies on a
fresh machine; processing a meeting must not call a network service.

### Smoke tests

Command: `tests/run.sh --smoke`

Expected result: The package builds and CLI help prints usage without reading
a meeting recording or contacting a network service. The current smoke test
checks the implemented `import` command. When the three-command revision is
accepted and implemented, the smoke test must check `transcribe`,
`recognize`, and `summarize` instead.

### Unit tests

Command: `tests/run.sh --unit`

Expected result: Named Swift Testing core cases pass without audio, video,
transcript, or metadata from real meetings. `swift test` is the direct package
sanity check, but the RUP gate uses the runner above.

### Integration tests

Command: `tests/run.sh --integration`

Expected result: Named Swift Testing integration cases validate synthetic
local fixtures, source references, correction persistence, minutes/action
traceability, and opening a CLI-created record by its local identifier.
The requested separate CLI commands need revised test specifications and
new runner entries after managed-mode design approval.

## Local-only test-data policy

Tests must use synthetic or explicitly approved local fixtures. They must not
send data to the internet or depend on a network service. No real meeting
audio, video, transcript, or metadata may be added to the repository or test
logs.

## Operational validation

PBI-011/PBI-018 must define and perform the applicable manual checks for local
recording transcription, optional recognition, optional summary, local-model
execution, low-quality-audio warnings and review, and opening a CLI-created
record in the review player. The AMI meeting fixture and model weights remain
outside Git. Live capture is deferred. iOS portability is checked by building
and testing `MeetingCore` without macOS-only imports; it does not require an
iOS app in Sprint 2.

## Acceptance gate

The PBI-009 acceptance gate selected Swift, Swift Testing, and local fixtures.
The current profile records the working runner commands. Revising CLI
semantics requires corresponding smoke, unit, integration, and manual
validation changes before the new behavior can pass Sprint 2 gates.
