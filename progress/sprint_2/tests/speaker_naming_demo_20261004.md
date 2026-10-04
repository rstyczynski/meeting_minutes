# Sprint 2 — Speaker naming in the Product Owner demo

## Intent and boundary

The Product Owner requested that the presentation explain how to assign a
speaker name from the CLI. Slide 10 and stage 4 of the
[live demo](../demo/README.md) now show the operation, saved result and
required reopening of Meeting Review. A name applies to the whole existing
speaker cluster. This test checks CLI persistence, not a person's identity
or the correctness of diarization.

## Executed check — 2026-10-04

The real Sejm record `5C00CCF3-A242-4FB0-845D-92C6D30D7633` was copied from
the active demo store to `/private/tmp/meeting-sprint2-naming-check.LbgE0f`.
The active record had no speaker names. The disposable copy was edited with:

```bash
swift run meeting-summarizer recognize name \
  5C00CCF3-A242-4FB0-845D-92C6D30D7633 S2 'CLI naming contract check' \
  --store /private/tmp/meeting-sprint2-naming-check.LbgE0f
```

Expected: exit 0, the same meeting UUID on stdout, and the supplied label in
`speakerNames.S2`, with raw segments unchanged. Observed: all expectations
passed. A direct comparison also confirmed the active source record still
had an empty name map. The contract-check label is not a verified meeting
participant and does not enter the live Product Owner record.

## Presentation and script checks

The [updated deck](../sprint_2_increment_demo_naming_20261004.pptx) has 18
slides. Its [finalization receipt](presentation_validation_naming_20261004.json)
records package, font, chart and reimport checks. Every final slide was
rendered; slide 10 and both charts were inspected at full size, and the
whole deck was scanned for unintended changes. Slide 16's text-frame
overlap warnings were visually checked: the rebuilt chart labels remain
readable without visible clipping.

Stage 4 prints the complete command with the current UUID, entered name
and store before execution, then prints the saved name map and the exact
Meeting Review reopening command. Shell syntax and the demo's `--check`
preflight passed. This documentation increment does not change product
code or model prompts; ASR and minutes benchmarks were not rerun.

Human listening, real identity verification, the name's display after app
reopening, and the Product Owner handover decision remain live checks.
