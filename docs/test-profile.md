# Project test profile

Status: Accepted Sprint 1 test profile; Sprint 2 commands reconciled

## Purpose

This document maps the RUP test levels to Meeting Summarizer's actual build,
test, and operational-validation commands. PBI-009 established the profile
before Sprint 2. The active sprint uses the checked-in `tests/run.sh` runner
and its `new_tests.manifest`. The Product Owner chose the open-source Swift
Testing package when only Apple Command Line Tools were installed. Xcode is
now installed for the MLX Metal experiment; the approved test library remains
Swift Testing.

## Required Sprint 2 settings

Sprint 2 requires `Test: smoke, unit, integration` and `Regression: smoke,
unit, integration`.

## Current commands

Run these commands from the repository root. The runner accepts `--new-only
progress/sprint_2/new_tests.manifest` for the Sprint 2 new-work gates and
runs its full suite without that option for regression. The manager records
each formal gate in a timestamped log under `progress/sprint_2/tests/`.

The single entry point for the complete Sprint 2 quality sequence is
`tests/run-sprint-gates.sh progress/sprint_2 [log-label]`. It runs A1 smoke,
A2 unit, A3 integration, B1 smoke, B2 unit, and B3 integration in order,
writes a separate timestamped log for each, and stops at the first failure.
Use a label such as `pbi3` to distinguish a child PBI's run. On this Mac,
SwiftPM's nested sandbox fails before tests run; execute this wrapper outside
the sandbox once rather than requesting permission for each gate separately.

The Product Owner added FR-11 English and Polish transcription validation to
the active sprint after the English-only runs. Its accepted design adds a
language-control smoke check, compatibility/provenance unit check, persisted
CLI integration check, and real multilingual model comparison. The FLEURS
experiment uses pinned English and Polish references and reports Unicode
word and character error. The earlier 18 automated cases and AMI results
alone do not validate Polish; the new operational evidence is in the Sprint 2
[benchmark](../progress/sprint_2/ami_asr_benchmark.md).

### Build

Command: `swift build`

Expected result: The `MeetingCore` library and `meeting-summarizer` executable
compile successfully. Package resolution may fetch source dependencies on a
fresh machine; processing a meeting must not call a network service.

### Smoke tests

Command: `tests/run.sh --smoke`

Expected result: The package builds and CLI help advertises `transcribe`,
`recognize`, and `summarize` without reading a recording or contacting a
network service. The smoke test also checks the compatible `import` route.

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
The separate CLI commands have approved functional checks IT-7 through IT-9,
including saved-state checks after each optional step.

## Local-only test-data policy

Tests must use synthetic or explicitly approved local fixtures. They must not
send meeting data to the internet or depend on a network service during
inference. Private meeting audio, video, transcripts, and metadata must not
be added to the repository or test logs. Approved public meeting excerpts
may be retained as Sprint evidence when the source, rights, and Product
Owner approval are recorded; large media and model weights stay outside
Git. The AMI, Sejm, and DOE fixture records document those exceptions.

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
The current profile records the working runner commands. Sprint 2's accepted
CLI revision has corresponding smoke, unit, integration, and manual checks;
their outcomes are recorded in the [Sprint 2 test record](../progress/sprint_2/sprint_2_tests.md).

## Reading-policy correction coverage — 4 October 2026

The existing UT-14 transcript-cleaning case exercises every configurable reading control and protects continuous same-speaker speech across the former duration and pause cuts. The existing IT-13 multi-stage CLI case checks saved-profile application and propagation into captured model input, source/name preservation, stale-result invalidation and byte-preserving rejection/no-op behavior. Both remain selected in the Sprint 2 manifest; the six-gate wrapper command is unchanged. Native playback requires a human check and is not implied by these automated gates.
