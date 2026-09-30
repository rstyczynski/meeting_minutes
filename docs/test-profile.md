# Project test profile

Status: Accepted candidate architecture

## Purpose

This document maps the RUP test levels to Meeting Summarizer's actual build,
test, and operational-validation commands. It must be completed and accepted
as part of PBI-009 before Sprint 2 begins. Until then, it is a planning
template, not evidence that the project can run code-bearing quality gates.

## Required Sprint 2 settings

Sprint 2 requires `Test: smoke, unit, integration` and `Regression: smoke,
unit, integration`.

## Commands to define in PBI-009

The accepted candidate architecture must replace each pending field below with
an exact, copy-pasteable command and its expected result.

### Build

Command: `swift build`

Expected result: The `MeetingCore` library and `meeting-summarizer` executable
compile successfully without fetching or calling a network service.

### Smoke tests

Command: `swift run meeting-summarizer --help`

Expected result: The CLI prints its local-only import usage and exits without
reading a meeting recording or contacting a network service.

### Unit tests

Command: `swift test`

Expected result: Core logic tests pass without audio, video, transcript, or
metadata from real meetings.

### Integration tests

Command: `swift test --filter MeetingIntegrationTests`

Expected result: Synthetic local fixtures validate import, source references,
speaker correction persistence, minutes/action traceability, and opening a
CLI-created record by its local identifier without network access.

## Local-only test-data policy

Tests must use synthetic or explicitly approved local fixtures. They must not
send data to the internet or depend on a network service. No real meeting
audio, video, transcript, or metadata may be added to the repository or test
logs.

## Operational validation

PBI-011/PBI-012 must define and perform the applicable manual checks for local
recording import, local-model execution, and opening a CLI-created record in
the review player. Live capture is deferred. iOS portability is checked by building and testing
`MeetingCore` without macOS-only imports; it does not require an iOS app in
Sprint 2.

## Acceptance gate

Before Sprint 2 changes to `Progress`, PBI-009 must select the toolchain,
replace all pending command fields, and obtain Product Owner acceptance of this
profile.
