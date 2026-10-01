# Sprint 2 — Functional test record

Status: PBI-011.1 passed its completion gates and was committed. The other Sprint 2 children and PBI-018 have working construction checks and still require their own final six-gate runs, documentation reconciliation, board updates, and local completion commits. The [implementation record](sprint_2_implementation.md) gives working user commands; this record reports test intent, expected result, observed result, and limits.

## Environment and fixtures

The tests run from the repository root on macOS with Swift 6.3.3 and the pinned open-source Swift Testing 6.3.2 package. Xcode 27 is installed for the MLX Metal experiment. The synthetic WAV and reference JSON are invented and checked in. AMI ES2002a audio and annotations were approved by the Product Owner and are held outside Git with the local models. Their source, license, and hashes are in [the fixture record](ami_es2002a_fixture.md). The synthetic tests need no credentials or meeting service.

## Build and automated contracts

Command: swift build. Expected: the portable core, CLI, and SwiftUI app compile. Observed: PASS after the accepted three-command implementation and bounded player change. Xcode prints repeated PIF warnings about an unknown platform named DoesNotExist, but the build exits successfully.

Command: swift test. Expected: unit and integration contracts pass. Observed: PASS on 2026-10-01 at 15:25 local time: nine MeetingCoreTests and nine MeetingIntegrationTests, 18 total, zero failures. The core tests cover record validation, atomic storage, configuration, transcript-only behavior, optional minutes, chair correction, and invalid inputs. The integration tests cover CLI-created record reload, fixture generation, source links, backend selection, the three-command flow, neutral summary, source-chunk merging, failure preservation, and correction/review.

The test-only reference path proves contract behavior, not ASR or language-model accuracy. The six RUP gates below use tests/run.sh rather than substituting this direct swift test check.

## CLI functional sequences

SM-2 expects CLI help to advertise transcribe, recognize, and summarize. The smoke wrapper checks all three and the compatible import route. The executable now prints those commands. The current A1 and B1 gates passed after help was corrected to mention import.

IT-7 transcribes the invented WAV through fixture-reference, reloads the saved UUID, and expects five timed segments, backend provenance, and no review items. The CLI produced those fields. The missing-media command prints Media file does not exist, exits 2, and saves no replacement record. The three-command integration test and current A3 and B3 gates pass.

IT-8 recognizes anonymous speakers, assigns the name Ada to speaker_2, moves turn_1, and reloads the same record. The saved record retained the name and correction. Invalid record, speaker, or segment operations preserve the earlier JSON. The chair correction and failure-preservation tests pass. Real FluidAudio recognition assigned anonymous S1/S2/S3 labels to the full AMI record and persisted 16 quality-warning ranges. It does not identify real people by voice.

IT-9 runs summarize separately after transcribe, with and without recognize. The fixture case adds four review items to the same UUID: summary, decision cited to turn_3, action cited to turn_4 with speaker_2 owner, and open question cited to turn_5. The neutral-summary path passes without chair name assignment. The local MLX model also completed this invented-meeting path in saved record 8DAAA0BB-C4A0-4863-9198-025E9FD4E643; that is an adapter execution check and small content sanity check, not natural-meeting quality evidence.

The exact copyable command sequence and the cat/jq human rendering are in [the implementation record](sprint_2_implementation.md). A missing configured model fails before overwriting the transcript. Unknown source IDs and unsupported owner IDs are guarded by validation or omission, so they cannot silently become invented persisted owners.

## Natural-meeting and model checks

Both ASR engines processed the same AMI headset mix, with the same manual reference and scoring normalization. FluidAudio WER was 19.48%; whisper.cpp WER was 28.79%. For the documented poor-headset speaker A, reference-linked errors were 27.78% and 58.55%. The separate lapel condition improved A's errors for both engines but worsened overall WER. Three repeated 120-second runs per engine measured wall time and process resident memory. Model footprint, timestamp diagnostics, model revisions, input hashes, raw output paths, scoring commands, and limitations are in [the benchmark report](ami_asr_benchmark.md). Staged Fluid ASR, whisper.cpp ASR, and Fluid diarization emitted nonempty JSON under a process-level network denial.

The low-quality-audio check is partial. The Fluid diarizer made only three anonymous clusters for four reference people, merging A and C. Sixteen low-level S3 warning ranges covered 186 of A's 233 annotated words but also 83 other-speaker words. The CLI persisted those warnings in real record 87A64680-FD3C-44D4-9529-039E7071E46A. The SwiftUI app loaded that record, showed its warnings, and sought local audio to selected warning and transcript times. The warning cannot yet reliably name the affected person. An alternate-input operator comparison is not implemented, so FR-09 and FR-10 are not fully validated.

The MLX minutes experiment used Qwen3-4B-Instruct-2507 4-bit on the invented fixture and the first 120 seconds of AMI. The invented meeting produced plausible, source-linked items. On AMI, feeding 210 word segments directly gave truncated JSON; grouping them into short traceable source chunks produced valid persisted JSON in record 4604E907-2EE9-4FE6-974A-8D22A5F9914D. Content review found a project goal recast as a decision, two actions without source commitments, and two questions never asked. The model also attempted an unsupported owner, which the adapter omitted. Natural minutes quality therefore fails this sample. The prototype exposes the evidence; Sprint 3 must analyze the model and workflow choice. The model does not establish a production minutes capability.

The review player initially crashed when AVKit VideoPlayer was used. The AVFoundation replacement built and loaded the real record; seeking to warning and transcript ranges worked. Continuous playback was disruptive, so the current player pauses after the selected range. The bounded replay change builds but has not been manually replayed since the user closed the preview. The accepted PBI-011.4 criterion was build, manual open/seek, and CLI-created record integration, all of which passed; bounded pause behavior is a documented follow-up limit and was not presented as manually verified.

## Prescribed RUP gates

Each completed child or increment requires a new-work smoke, unit, and integration run, then full-regression smoke, unit, and integration run. Run the following from the repository root and save timestamped output in progress/sprint_2:

The main entry point runs the complete sequence and writes the six logs:

~~~bash
tests/run-sprint-gates.sh progress/sprint_2 pbi3
~~~

The entry point executes these underlying commands in order:

~~~bash
tests/run.sh --smoke --new-only progress/sprint_2/new_tests.manifest
tests/run.sh --unit --new-only progress/sprint_2/new_tests.manifest
tests/run.sh --integration --new-only progress/sprint_2/new_tests.manifest
tests/run.sh --smoke
tests/run.sh --unit
tests/run.sh --integration
~~~

For PBI-011.1, all six passed. A1 first failed at SwiftPM's nested sandbox before product assertions; the outside-sandbox retry passed. A3 and B3 were rerun successfully after IT-1 was strengthened. The logs are test_run_A1_smoke_20261001_090052.log (sandbox failure), test_run_A1_smoke_20261001_090116_retry1.log (PASS), test_run_A2_unit_20261001_095313.log (PASS), test_run_A3_integration_20261001_095611.log (PASS), test_run_B1_smoke_20261001_095330.log (PASS), test_run_B2_unit_20261001_095337.log (PASS), and test_run_B3_integration_20261001_101632.log (PASS). Earlier A3/B3 logs at 095322/095343 also passed before the IT-1 change. IT-1 launched the CLI in a separate process and reloaded its record through MeetingStore, satisfying that child's persistence criterion.

For PBI-011.3, the fixture generator was copied to /private/tmp/meeting-fixture-regenerate-pbi3 and executed there, leaving the checked-in fixture unchanged. The generated WAV had a 16,000 Hz sample rate, one channel, two bytes per sample, 16.727 seconds duration, and five reference turns. The source-linked output and reloaded chair corrections are covered by the passing integration cases. Fresh A1, A2, A3, B1, B2, and B3 logs named test_run_pbi3_A1_smoke_20261001_1552.log through test_run_pbi3_B3_integration_20261001_1552.log all ended successfully; each level used its required new-only or full-regression mode. The generator's macOS voices needed an outside-sandbox run, while the six gates passed on their first attempts.

After the Product Owner requested a single test entry point, tests/run-sprint-gates.sh was added and syntax-checked with bash -n. Its full PBI-011.3 run also passed all six levels, writing test_run_pbi3_A1_smoke_20261001_171053.log through test_run_pbi3_B3_integration_20261001_171053.log. The command prefix received one outside-sandbox approval for future runs, avoiding separate approval prompts for each gate. The earlier successful per-level logs remain as evidence of the pre-wrapper run.

For PBI-011.4, the same wrapper ran once with label pbi4; A1/A2/A3/B1/B2/B3 all passed in test_run_pbi4_A1_smoke_20261001_171356.log through test_run_pbi4_B3_integration_20261001_171356.log. Its integration suite includes loading a CLI-created synthetic record. The separate manual local run described above confirmed the SwiftUI app opened a real saved record and sought its audio. The player was left closed at the Product Owner's request.

For the current PBI-011.2 increment, A1 first failed at SwiftPM's nested sandbox, then its outside-sandbox retry failed because help omitted the still-supported import route. After correcting help, A1 passed in test_run_A1_smoke_20261001_152814_retry2.log. A2, A3, B1, B2, and B3 passed in test_run_A2_unit_20261001_1530.log, test_run_A3_integration_20261001_1530.log, test_run_B1_smoke_20261001_1530.log, test_run_B2_unit_20261001_1530.log, and test_run_B3_integration_20261001_1530.log. The two failed A1 attempts remain in test_run_A1_smoke_20261001_152814.log and test_run_A1_smoke_20261001_152814_retry1.log for traceability. The current run includes all 18 automated cases. The documentation audit must verify every affected artifact, commands, links, content claims, open risks, and git diff --check before each local completion commit. Later children need their own fresh logs and audit. No Sprint 2 parent item is currently marked tested.
