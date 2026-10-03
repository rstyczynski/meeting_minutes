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
