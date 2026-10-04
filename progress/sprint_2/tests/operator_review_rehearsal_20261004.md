# Sprint 2 operator-review rehearsal — 4 October 2026

This is a developer rehearsal of the implemented review contracts, not an
audio-verified correction or a live Product Owner demonstration. The real
multi-person input is the saved ten-minute Sejm record
`5DC83D71-D1B0-4568-A66D-70F3B9A71D46`. Its unchanged JSON copy was
loaded from `/private/tmp/meeting-sprint2-handover-rehearsal/` and has
SHA-256 `eb44206c0ffc27a4f4b5be9e70d7f3101cbd393212bfba4ec585abf7390c820b`.
The [source record](5DC83D71-D1B0-4568-A66D-70F3B9A71D46.json) is also
retained in this test directory.

## Real transcript: review target and proposed join

The supported `swift run meeting-summarizer inspect-cleanup` command ran on
the saved Sejm record and returned [machine-readable output](operator_cleanup_rehearsal_20261004.json):
16 proposed joins and 32 reading utterances. Four `joinPrevious` proposals
concern raw `segment_758` through `segment_761`, from 565.36 to 569.04
seconds. Their original speaker IDs are unassigned and their words are
“przedstawienie tej tego budżetu.” The derived `utt_30` places these IDs
with the preceding S1 chair turn. This is an inspectable continuity
proposal, not proof from audio that the same person spoke. The raw segment
IDs, words, times, and unassigned labels were not changed.

The operator should open that record in Meeting Review, seek to the 565–569
second range, listen to both neighboring turns, and either confirm or
reject the proposed continuity before changing a speaker label or text.
The saved source path points to the staged Sejm WAV. No voice identity has
been verified for the whole S1 cluster, so no participant name was assigned
in this rehearsal.

## Correction protection and controlled tests

The command `swift run meeting-summarizer transcribe correct
5DC83D71-D1B0-4568-A66D-70F3B9A71D46 segment_758 'przedstawienie'
--store /private/tmp/meeting-sprint2-handover-rehearsal` was deliberately
run **without** `--audio-reviewed yes`. It exited 2 with `Adapter failed:
Use --audio-reviewed yes after listening to the source range`. The record's
SHA-256 remained the same. This shows the CLI guard; it does not establish
that an operator actually listened.

The focused [reversible-correction unit test](operator_review_unit_20261004.log)
passed. Its controlled record starts with raw “thirty five million,” adds
an audio-reviewed correction to “thirty five billion,” verifies that the
reading view changes while raw ASR stays intact and old draft minutes are
cleared, then adds a second correction restoring the original words. It
verifies two retained correction entries. This is a test with a simulated
confirmation flag, **not** evidence that the developer heard the recording.
The focused [CLI/store integration test](operator_review_integration_20261004.log)
and [manual speaker-correction unit test](speaker_move_unit_20261004.log)
also passed, one test each. They verify storage and edit contracts, not
audio-level accuracy or a participant's identity.

## Player and identity boundary

`swift run meeting-review <record-id> --store <directory>` built and
started, but this session's native UI controller could not attach to the
process or find its window. The developer stopped it rather than leaving
audio playback running. Therefore source-range seek, bounded stop,
listening, a real-audio before/after word correction, undo after a second
listen, and a verified speaker reassignment remain **unobserved in this
rehearsal**. They must be performed with the Product Owner in the live
session before those actions are claimed as demonstrated. AMI's three
clusters for four reference people remain an independent speaker-detection
failure; the correction contract does not repair that merge by itself.
