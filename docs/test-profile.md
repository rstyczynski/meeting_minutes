# Project test profile

Status: Pending candidate architecture

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

Command: Pending candidate architecture

Expected result: Pending candidate architecture

### Smoke tests

Command: Pending candidate architecture

Expected result: The application or prototype builds and starts its local
critical path without network access.

### Unit tests

Command: Pending candidate architecture

Expected result: Core logic tests pass without audio, video, transcript, or
metadata from real meetings.

### Integration tests

Command: Pending candidate architecture

Expected result: Synthetic local fixtures validate the prototype's selected
end-to-end paths without network access.

## Local-only test-data policy

Tests must use synthetic or explicitly approved local fixtures. They must not
send data to the internet or depend on a network service. No real meeting
audio, video, transcript, or metadata may be added to the repository or test
logs.

## Operational validation

PBI-011/PBI-012 must define and perform the applicable manual checks for macOS
permissions, recording import, live capture, local-model execution, and UI/CLI
event cooperation. PBI-009 must also state how iOS portability will be checked
without requiring an iOS implementation in Sprint 2.

## Acceptance gate

Before Sprint 2 changes to `Progress`, PBI-009 must select the toolchain,
replace all pending command fields, and obtain Product Owner acceptance of this
profile.
