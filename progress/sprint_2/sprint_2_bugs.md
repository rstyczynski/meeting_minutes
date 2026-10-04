# Sprint 2 bugs

The Product Owner has stated that the increment is not ready for delivery.
The open minutes defects below block handover acceptance. Their detailed
same-input measurements are in the [benchmark](ami_asr_benchmark.md#polish-meeting-minutes-quality-check);
raw run captures are test evidence, not the decision report.

## BUG-1: Speaker label used as a minutes source ID

**Item:** PBI-011.5

**Severity:** high

**Status:** fixed

- **Symptom:** The first Polish Sejm `summarize --summarizer mlx` attempt exited 2 with `Unknown source segment: S1`; `S1` was a speaker label, not a transcript segment ID. The [run capture](tests/polish_sejm_meeting_run_20261002.json) records the attempt.
- **Root cause:** The model-facing transcript format did not clearly distinguish source IDs from speaker IDs, and the adapter had no recovery path for an invalid citation.
- **Fix:** `MeetingMLXMinutes` now labels `SOURCE_ID` and `SPEAKER` separately and retries once after an invalid source citation. `MeetingCore` also drops an action owner whose cited segments do not contain that speaker.
- **Verification:** The focused citation/owner regression and all six [final Sprint gate runs](sprint_2_tests.md#polish-multi-person-meeting-correction--2026-10-02) passed. The direct Sejm rerun exited 0 and persisted four draft items. Content quality remains a separate open defect.

## BUG-2: Natural-meeting minutes contain unsupported claims

**Item:** PBI-011.5

**Severity:** high

**Status:** open

- **Symptom:** On the real Polish Sejm meeting, the 4B model saved a valid decision but also a false action and an invented open question; its summary had no source citation. The 7B alternative changed the summary to English and cited a decision range ending before the decision, while misclassifying an agenda transition as an action. See the [Sejm run capture](tests/polish_sejm_meeting_run_20261002.json) and [item-level benchmark assessment](ami_asr_benchmark.md#polish-meeting-minutes-quality-check).
- **Root cause:** Valid JSON and existing source IDs do not establish that the cited words support a generated claim. The tested model/prompt combinations did not preserve source-grounded content and language on this meeting.
- **Fix:** The approved evidence-first gate now withholds malformed or uncited responses and requests at most two repairs. It prevents unsupported draft items from being saved but does not make generated content useful. No model has been promoted as a dependable default.
- **Verification:** The [30B same-input trial](tests/qwen3_30b_minutes_trial_20261003.md) retained all raw attempts and manually reviewed the cited words. AMI yielded only a brief quotation; Sejm failed JSON and source coverage. The draft is not publishable; passing structural gates does not close this bug.

## BUG-3: Long English meeting produces no minutes items

**Item:** PBI-011.5

**Severity:** high

**Status:** open

- **Symptom:** On the same 30-minute DOE transcript, Qwen3-4B and Qwen2.5-7B both exited 2 while reading generated structured output, and each store retained zero review items. Exact errors and run IDs are in the [DOE capture](tests/doe_itiac_day2_run_20261002.json).
- **Root cause:** A direct same-input 4B adapter run retained its raw response. It ended mid-string after 3,715 characters, so JSON decoding necessarily failed. The adapter had requested at most 1,024 generated tokens; the model ignored its limits of two items and three citations per item, produced long citation arrays, and exhausted the response budget. This proves truncation for the 4B attempt. The 7B attempt still lacks raw output, so its exact failure remains unproven. See the [diagnostic](tests/doe_minutes_failure_diagnosis_20261002.md).
- **Fix:** The approved evidence-first design now rejects minutes input over 600 seconds, offers opt-in local raw-response diagnostics, and checks generated quotations against cited source ranges. A full DOE recheck under that limit was not run because the 30-minute input is deliberately outside prototype scope.
- **Verification:** Pending. The [DOE fixture](doe_itiac_day2_fixture.md) and identical saved transcript provide a repeatable real-audio case.

## BUG-4: Direct debug-binary minutes launch aborts on this host

**Item:** PBI-011.5

**Severity:** medium for the documented `swift run` route; high for a standalone binary

**Status:** open, supported route identified

- **Symptom:** The direct `.build/debug/meeting-summarizer summarize` path aborted inside MLX with `NSRangeException` before returning an adapter result. On the same copied short AMI record, `swift run --skip-build meeting-summarizer summarize` succeeded, demonstrating that recompilation is not required for success.
- **Root cause:** Not established. The different launch context is material; a specific Metal, entitlement, or sandbox cause has not been proven.
- **Containment:** The Elaboration manual and handover use `swift run` for the live journey, as the Product Owner allowed. No standalone-binary minutes support is claimed.
- **Verification:** The [reproduction record](tests/doe_minutes_failure_diagnosis_20261002.md#direct-cli-launch-check) gives the same-record commands and results. A standalone release path still needs a separate supported-environment check.


## BUG-5: Arbitrary reading cuts split a continuous utterance

The Product Owner observed S3 split at 597.0 seconds because the reading layer capped blocks at 15 seconds, and S2 split between `35` and `779` because a 1.6-second pause exceeded a separate 1.5-second reading gap limit. Neither boundary had semantic justification. The defects are in Swift reading segmentation, not proof of an ASR or diarization failure.

Status: reading-rule correction implemented and covered by UT-14 and IT-13; live operator acceptance remains pending. That checkpoint disabled both cuts and exposed ten controls; BUG-8 below supersedes its unlimited-silence default while keeping the duration cap disabled. The [configuration receipt](tests/cleanup_configuration_20261004.json) shows 32-to-four reading blocks with 802/802 source parts conserved. An early configuration test additionally caught a no-op profile application rewriting JSON; the CLI now skips that save. Semantic boundary validation and independent voice reassessment remain separate open work. See the [implementation](sprint_2_implementation.md) and [segmentation contract](transcript_segmentation.md).

## BUG-6: Word-sized correction playback is too short for operator review

**Item:** PBI-011.5, supporting PBI-011.4

**Severity:** high

**Status:** open

**Symptom:** During review of Sejm record `5C00CCF3-A242-4FB0-845D-92C6D30D7633` in `/private/tmp/meeting-sprint2-po-demo.Ry3oFz`, the Product Owner reported that the editor exposes words individually and their audio is too short to hear, requesting a selected-text correction action instead.

**Root cause:** The editor targets one raw source part, which can be a single word, and plays only that part's timestamp range without context. Existing playback also starts a wall-clock stop timer before asynchronous seek completion. Controlled GUI tests exercised text storage and confirmation with no audio; they therefore did not establish usability for real word-sized media. The timer is an additional identified risk, not a proven explanation of every inaudible attempt.

**Fix:** The accepted range editor offers exact phrase correction and configurable before/after audio. BUG-8 adds a position slider and long-silence boundaries. Code and storage checks passed; actual listening and remaining native controls require the live review.

**Verification:** Six range-compatibility gates and six long-silence gates passed. The owner session contains a successful crossing edit ([receipt](tests/selection_owner_session_20261004.json)). Actual slider seeking, audible bounds and remaining controls are pending; the earlier per-source GUI check is historical.



## BUG-7: Following correction cannot overlap a saved replacement

**Item:** PBI-011.5, supporting PBI-011.4

**Severity:** high

**Status:** fixed in code and observed saved-session replay; other native controls remain pending

**Symptom:** The Product Owner's [screenshot](tests/selection_overlap_user_failure_20261004.png) shows “Selection overlaps an existing correction; edit or restore that correction first” while saving “sygnał - od razu zaczynamy.” The current Sejm record has a prior correction over source parts `segment_73`–`segment_102`, ending in “proszę o sygnał.” A follow-up selection crossing that replacement into later source words was rejected.

**Root cause:** The first selection design expanded a touched replacement, but the save validator only accepted its exact original anchor key. A larger selection was treated as a conflicting independent correction. Moreover, expanding the visible target forced the operator to retype unselected surrounding words, creating a deletion risk.

**Fix:** `TranscriptSelection.swift` keeps the exact selected text as the editor target and separately expands storage anchors. Saving replaces that substring within the current projected text, preserving the unselected prefix/suffix. One atomic event supersedes touched active corrections by ID and retains their history. The editor explains the mapped Restore scope. Stale revisions remain rejected.

**Verification:** UT-19/IT-15 and all six `selection_compatibility_verified` gates passed at `20261004_230115`. The [read-only owner-session receipt](tests/selection_owner_session_20261004.json) observes the successfully saved native follow-up event, retained prefix and superseded history. Tests never wrote the live store. Restore/Cancel/restart and independent listening remain manual checks.

## BUG-8: Same-speaker grouping crosses 33 seconds of silence

**Item:** PBI-011.5, supporting PBI-011.4. **Severity:** high. **Status:** segmentation repair verified; native slider/listening check pending.

The Product Owner heard a long silence after “zaczynamy” but the same S1 card continued into the opening of the sitting. Source `segment_104` ends at 148.40 s and `segment_105` starts at 181.68 s: 33.28 seconds without a timed ASR part. The prior rule joined all consecutive same-speaker parts with no gap limit. ASR and diarization did not make this reading-layer decision.

The directed repair adds finite positive `longSilenceBoundarySeconds`, default 10 s, and starts another segment when the gap is greater than or equal to that setting, retaining the same label. The source/history remains untouched. A new full-recording slider in both review views supports inspection; scrubbing pauses and cancels the bounded request, release seeks, explicit Play resumes. Semantic topic recognition and new voice analysis are still absent.

UT-21/IT-16 and all six `long_silence_verified` gates passed at `20261004_230950`. [Full-record inspection](tests/long_silence_review_20261004.json) on a disposable copy yields five segments instead of four, preserves 802/802 parts and both correction events, and exposes the measured boundary reason. Native slider seeking and listening are pending; compilation is not a listening test.
