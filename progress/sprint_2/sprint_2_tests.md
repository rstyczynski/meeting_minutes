# Sprint 2 — Functional test record

Status: all five original PBI-011 children, the initial PBI-018 English benchmark, and the original PBI-011 parent scope passed separate six-gate runs. The approved FR-11 increment added a sixth child, PBI-011.6, whose six gates passed. English meeting, Polish read-speech, and later Polish multi-person meeting model runs were measured; the paired PBI-018 extension has a separate gate run. The completed technical measurement includes explicit model-quality failures and limits. The [implementation record](sprint_2_implementation.md) gives working user commands; this record reports test intent, expected result, observed result, and limits.

The [single-command Product Owner demo rehearsal](tests/po_demo_rehearsal_20261004.md)
is a separate real-model check on the current Mac. Its preflight passed;
its CLI stages saved fresh English and Polish transcripts, speaker labels,
warnings, and cleanup proposals. Fresh 30B minutes generation failed the
response gate twice and preserved both transcripts. The [live presenter
script](demo/README.md) shows that observed result and labels the earlier
successful 30B output as recorded comparison evidence. Operator listening,
audio-confirmed correction, name assignment, and Product Owner review were
not part of the automated rehearsal.

## Environment and fixtures

The tests run from the repository root on macOS with Swift 6.3.3 and the pinned open-source Swift Testing 6.3.2 package. Xcode 27 is installed for the MLX Metal experiment. The synthetic WAV and reference JSON are invented and checked in. AMI ES2002a audio and annotations were approved by the Product Owner and are held outside Git with the local models. Their source, license, and hashes are in [the fixture record](ami_es2002a_fixture.md). The synthetic tests need no credentials or meeting service.

## Build and automated contracts

Command: swift build. Expected: the portable core, CLI, and SwiftUI app compile. Observed: PASS after the accepted three-command implementation and bounded player change. Xcode prints repeated PIF warnings about an unknown platform named DoesNotExist, but the build exits successfully.

Command: swift test. Expected: unit and integration contracts pass. Observed: the original 18 cases passed on 2026-10-01 at 15:25 local time; FR-11 added one core and one integration case, and all 20 passed in the PBI-011.6 six-gate run. The core tests cover record validation, atomic storage, configuration, transcript-only behavior, optional minutes, chair correction, language/model compatibility, and invalid inputs. The integration tests cover CLI-created record reload, fixture generation, source links, backend selection, the three-command flow, neutral summary, source-chunk merging, failure preservation, correction/review, persisted language, and English-only model rejection.

The test-only reference path proves contract behavior, not ASR or language-model accuracy. The six RUP gates below use tests/run.sh rather than substituting this direct swift test check.

## CLI functional sequences

SM-2 expects CLI help to advertise transcribe, recognize, and summarize. The smoke wrapper checks all three and the compatible import route. The executable now prints those commands. The current A1 and B1 gates passed after help was corrected to mention import.

IT-7 transcribes the invented WAV through fixture-reference, reloads the saved UUID, and expects five timed segments, backend provenance, and no review items. The CLI produced those fields. The missing-media command prints Media file does not exist, exits 2, and saves no replacement record. The three-command integration test and current A3 and B3 gates pass.

IT-8 recognizes anonymous speakers, assigns the name Ada to speaker_2, moves turn_1, and reloads the same record. The saved record retained the name and correction. Invalid record, speaker, or segment operations preserve the earlier JSON. The chair correction and failure-preservation tests pass. Real FluidAudio recognition assigned anonymous S1/S2/S3 labels to the full AMI record and persisted 16 quality-warning ranges. It does not identify real people by voice.

IT-9 runs summarize separately after transcribe, with and without recognize. The fixture case adds four review items to the same UUID: summary, decision cited to turn_3, action cited to turn_4 with speaker_2 owner, and open question cited to turn_5. The neutral-summary path passes without chair name assignment. The local MLX model also completed this invented-meeting path in saved record 8DAAA0BB-C4A0-4863-9198-025E9FD4E643; that is an adapter execution check and small content sanity check, not natural-meeting quality evidence.

The copyable test-only command sequence and the cat/jq human rendering follow below. A missing configured model fails before overwriting the transcript. Unknown source IDs and unsupported owner IDs are guarded by validation or omission, so they cannot silently become invented persisted owners.

## Synthetic CLI contract check — test-only reference path

Run from the repository root on macOS with Swift and jq installed. This is a
CLI and storage test only. The WAV and reference JSON are paired invented test
files; each transcribe command prints a new UUID. Later commands print that
same UUID. The test-only `--fixture-reference` option supplies prewritten
transcript, speaker, or minutes data at each step, bypassing model inference.

~~~bash
record_id="$(swift run meeting-summarizer transcribe tests/fixtures/synthetic_meeting.wav --transcriber fluid --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo)"
printf 'Record: %s\n' "$record_id"
swift run meeting-summarizer recognize "$record_id" --diarizer fluid --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo
swift run meeting-summarizer recognize name "$record_id" speaker_2 Ada --store /private/tmp/meeting-sprint2-demo
swift run meeting-summarizer recognize move "$record_id" turn_1 speaker_2 --store /private/tmp/meeting-sprint2-demo
swift run meeting-summarizer summarize "$record_id" --summarizer mlx --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo
~~~

Recognize and summarize may each be skipped. To check transcript-only operation, stop after the first command; reviewItems is then empty. To generate minutes without recognizing speakers, run summarize directly after transcribe; the summary retains neutral or unknown labels. The name and move commands are chair corrections, not automatic voice identity discovery. Fluid's diarizer detects anonymous voices only.

Immediately after the commands, print a concise human view of the saved JSON. This is the requested cat/jq result after CLI use:

~~~bash
cat "/private/tmp/meeting-sprint2-demo/$record_id.json" | jq -r '
  "Meeting: \(.id)",
  "Source: \(.sourcePath)",
  "Backend: \(.backend) (\(.modelRevision))",
  "Speaker names: \(.speakerNames | to_entries | map("\(.key)=\(.value)") | join(", "))",
  "",
  "Transcript:",
  (.segments[] | "  [\(.range.startSeconds)-\(.range.endSeconds)s] \(.speakerID // "unknown"): \(.text)"),
  "",
  "Minutes and review:",
  (.reviewItems[] | "  \(.kind): \(.text) [source: \(.sourceSegmentIDs | join(", "))]" +
    (if .ownerSpeakerID then " [owner: \(.ownerSpeakerID)]" else "" end))
'
~~~

In the verified flow, the result has five timed turns and four review items: one summary, the turn_3 decision, the turn_4 action owned by speaker_2, and the turn_5 open question. speakerNames maps speaker_2 to Ada. The move makes turn_1 belong to speaker_2. A new UUID is generated each time, so use the shell variable rather than a UUID copied from this document.

The sequence was rerun for the documentation review. Its human-readable
check reported this result; the UUID will differ on another run:

~~~text
Turns: 5
Chair name: Ada
Corrected first turn: speaker_2
Review items: 4
summary: The group planned a same-recording comparison of two transcription engines.
decision: Test both transcription engines on the same recording
action: Write the reference transcript by Thursday
openQuestion: Who will check the speaker labels?
~~~

## Natural-meeting and model checks

The Product Owner's [four-step real-model walkthrough](sprint_2_implementation.md#product-owner-walkthrough--real-local-models)
was exercised on this Mac on 2026-10-02. Full English AMI transcription
created record `F4A47777-5288-4498-95D5-0A067D7DBA2E` with 2,576 timed
segments using Parakeet v2. Polish FLEURS transcription created record
`685ABDCF-BF44-42BA-9A9F-DD2F8734F6FA` with 15 Polish segments using
Parakeet v3. Real Fluid diarization on the full English record saved
anonymous IDs S1/S2/S3 and 16 low-speech-level warning ranges for S3;
the first begins at 19.32 seconds. The chair-name command saved
`S2 = Ada (demo label)`, a deliberate test label rather than an assertion
about participant identity.

The natural 120-second excerpt created record
`4CDA78E1-3E3A-4380-875B-CC976A53CB72`. It had 210 transcript segments,
S1/S2 labels, and no low-audio warnings; this is why the full meeting is
used for the warning demonstration. The real MLX adapter saved six review
items after the demo name was assigned. It repeated that invented name and
generated unsupported commitments or questions. Model execution passed,
but natural minutes content quality failed. The implementation record shows
the human-readable `jq` views; these saved records and the earlier scored
AMI and FLEURS evidence support each observed statement. No synthetic
reference option was used in this walkthrough. This documentation check
does not replace the previously completed six-gate PBI runs.

An attempt to run the entire Markdown walkthrough as a nested Bash process
inside the Codex filesystem sandbox failed before the first transcription:
SwiftPM could not apply its own sandbox while compiling the manifest. The
[failed attempt log](tests/product_owner_walkthrough_nested_sandbox_failure_20261002.log)
is retained. The direct `swift run` commands for English, Polish,
recognition, naming, and minutes each ran successfully outside that nested
execution attempt; the saved record IDs and `jq` views above are their
evidence. The integrated nested replay is not presented as a pass.

Both ASR engines processed the same AMI headset mix, with the same manual reference and scoring normalization. FluidAudio WER was 19.48%; whisper.cpp WER was 28.79%. For the documented poor-headset speaker A, reference-linked errors were 27.78% and 58.55%. The separate lapel condition improved A's errors for both engines but worsened overall WER. Three repeated 120-second runs per engine measured wall time and process resident memory. Model footprint, timestamp diagnostics, model revisions, input hashes, raw output paths, scoring commands, and limitations are in [the benchmark report](ami_asr_benchmark.md). Staged Fluid ASR, whisper.cpp ASR, and Fluid diarization emitted nonempty JSON under a process-level network denial.

The low-quality-audio check is partial. The Fluid diarizer made only three anonymous clusters for four reference people, merging A and C. Sixteen low-level S3 warning ranges covered 186 of A's 233 annotated words but also 83 other-speaker words. The CLI persisted those warnings in real record 87A64680-FD3C-44D4-9529-039E7071E46A. The SwiftUI app loaded that record, showed its warnings, and sought local audio to selected warning and transcript times. The warning cannot yet reliably name the affected person. An alternate-input operator comparison is not implemented, so FR-09 and FR-10 are not fully validated.

The MLX minutes experiment used Qwen3-4B-Instruct-2507 4-bit on the invented fixture and the first 120 seconds of AMI. The invented meeting produced plausible, source-linked items. On AMI, feeding 210 word segments directly gave truncated JSON; grouping them into short traceable source chunks produced valid persisted JSON in record 4604E907-2EE9-4FE6-974A-8D22A5F9914D. Content review found a project goal recast as a decision, two actions without source commitments, and two questions never asked. The model also attempted an unsupported owner, which the adapter omitted. Natural minutes quality therefore fails this sample. The prototype exposes the evidence; Sprint 3 must analyze the model and workflow choice. The model does not establish a production minutes capability.

The adapter's release build passed through the main package-path command. Xcode built MLX Swift's Metal library, which was copied beside the local executable. A separate MLX invocation under the same process-level network-denial profile exited 0 and produced parseable JSON with the invented meeting's decision, action, and open-question source IDs. The exact staged model revision and SHA-256 are in the implementation and benchmark records. This passes local-only execution on this Mac; it does not pass natural minutes quality or cross-device packaging.

The review player initially crashed when AVKit VideoPlayer was used. The AVFoundation replacement built and loaded the real record; seeking to warning and transcript ranges worked. Continuous playback was disruptive, so the current player pauses after the selected range. The bounded replay change builds but has not been manually replayed since the user closed the preview. The accepted PBI-011.4 criterion was build, manual open/seek, and CLI-created record integration, all of which passed; bounded pause behavior is a documented follow-up limit and was not presented as manually verified.

## Prescribed RUP gates

Each completed child or increment requires a new-work smoke, unit, and integration run, then full-regression smoke, unit, and integration run. Run the following from the repository root and save timestamped output in progress/sprint_2/tests:

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

For PBI-011.5, the wrapper ran once with label pbi5; A1/A2/A3/B1/B2/B3 all passed in test_run_pbi5_A1_smoke_20261001_171904.log through test_run_pbi5_B3_integration_20261001_171904.log. The release MLX adapter build, Xcode Metal library build, staged-model hash, and network-denial synthetic inference provide the separate operational evidence. The natural AMI minutes content failure remains a measured result and is not counted as a quality pass.

For PBI-018, the wrapper ran once with label pbi18; A1/A2/A3/B1/B2/B3 all passed in test_run_pbi18_A1_smoke_20261001_172200.log through test_run_pbi18_B3_integration_20261001_172200.log. The four stored ASR outputs were rescored against the same manual reference: headset WER 0.1948 for Fluid and 0.2879 for whisper.cpp, lapel WER 0.2195 and 0.3262. Replayed diarization scoring found three predicted clusters for four reference speakers, with headset 2219/2600 correct reference-word midpoints and lapel 2200/2600; the headset warning covered 186/233 words from affected speaker A and 83 words from others. Replayed timing diagnostics reported median absolute start/end errors of 0.07/0.07 seconds for Fluid and 0.46/0.51 for whisper.cpp, with the documented segment-size limitation. All values matched the self-contained benchmark report. This validates reproducibility of the Sprint 2 measurements; Sprint 3 remains responsible for architecture interpretation.

For the PBI-011.2 increment, A1 first failed at SwiftPM's nested sandbox, then its outside-sandbox retry failed because help omitted the still-supported import route. After correcting help, A1 passed in test_run_A1_smoke_20261001_152814_retry2.log. A2, A3, B1, B2, and B3 passed in test_run_A2_unit_20261001_1530.log, test_run_A3_integration_20261001_1530.log, test_run_B1_smoke_20261001_1530.log, test_run_B2_unit_20261001_1530.log, and test_run_B3_integration_20261001_1530.log. The two failed A1 attempts remain in test_run_A1_smoke_20261001_152814.log and test_run_A1_smoke_20261001_152814_retry1.log for traceability. The run includes all 18 automated cases. The separate child audits and local commits were completed. The parent PBI-011 six-gate run also passed with label pbi11 and stamp 20261001_172551; its documentation reconciliation is recorded in the audit.

After moving historical gate evidence to `progress/sprint_2/tests/`, the single wrapper ran again with label evidence_move. All six gates passed, writing six logs with stamp 20261001_191913 in that directory. This verifies the new output path as well as the unchanged product regression suite. The test-only fixture and English AMI result do not validate FR-11 Polish transcription.

## FR-11 bilingual checks

SM-3 expects CLI help to expose `--language en|pl|auto`; the final PBI-011.6 A1
and B1 gate logs show a pass. UT-10 expects English as the default, rejects
unknown codes, rejects Parakeet v2 and Whisper `.en` for Polish/auto, and
allows v3 and multilingual Whisper. IT-10 persists `requestedLanguage: pl`
in a transcript-only record, rejects invalid language and incompatible
model settings, and confirms the previous record remains readable. The
PBI-011.6 A2/A3/B2/B3 gates passed with these tests. The six passing gate
logs have stamp `20261001_211415`. The initial `pbi6_draft` and `pbi6`
logs are retained as failed attempts: new unit and integration cases did
not compile because the new test used `XCTAssertNoThrow`, which is absent
from this project's small Swift Testing assertion shim. The gate wrapper
then falsely printed success because its final timestamp command replaced
the test exit code. After the wrapper was fixed to propagate the test
status and the assertion was corrected, `pbi6_retry` stopped at A3 as it
should: the new test's two settings JSON files omitted required
`transcriber`. Those fixtures and the copyable settings example were
corrected before the final passing six-gate run. The failed logs remain
linked under Artifacts for traceability.

EXP-7 uses the real product CLI and the pinned FLEURS subset. It verified
five English and five Polish SHA-256 inputs, ran Parakeet v3 and multilingual
Whisper base on each, reloaded all 20 saved records, and scored Unicode WER
and CER. All 20 calls succeeded after Whisper was configured for CPU mode.
The first Whisper attempt with Metal failed before transcription with
`GGML_ASSERT(buffer)`; this is recorded as a model-loading failure. Both
Polish variants succeeded with process networking denied. The exploratory
English-plus-Polish `auto` splice failed to retain English in both engines.
The decision-facing scores and limitations are in the [benchmark report](ami_asr_benchmark.md);
the [manifest](tests/fr11_fleurs_manifest.json), [per-clip results](tests/fr11_fleurs_results.json),
and two mixed-language record files under `tests/` are the lower-level
evidence. The ten FLEURS clips are read speech and include both source gender
classes in each language, but have no verified speaker IDs. They do not
certify Polish meeting accuracy or a speaker-attribution
policy. Four additional [auto-language results](tests/fr11_auto_results.json)
used one English and one Polish clip with each backend. Each transcript
matched that backend's explicit-language result on the same clip. The
mixed splice still failed, so this is a single-language check only.

The first `pbi18_languages` wrapper attempt shares the false-positive
unit/integration problem above. The corrected wrapper and tests reran this
benchmark increment with label `pbi18_languages_final`; the passing logs
are linked under Artifacts. This gate
supplements the real-model comparison and does not erase the observed Metal
and language-switch failures.

The reopened PBI-011 parent then ran the corrected wrapper after the
PBI-011.6 and PBI-018 completion commits. All six parent gates passed with
stamp `20261001_213621`; their logs end with explicit PASS and are linked
below. The parent pass supports the implemented Sprint 2 board state; it
does not make the natural-minutes, diarization, or mixed-language quality
findings pass.

## Artifacts

Every saved RUP gate log is listed below from the Sprint 2 `tests/` evidence directory. Failed attempts remain for diagnosis; the passing replacement is identified in the gate narrative above.

The separate [Product Owner walkthrough nested-sandbox failure log](tests/product_owner_walkthrough_nested_sandbox_failure_20261002.log)
is retained here as documentation-check evidence. It is not one of the 98
RUP gate logs and does not replace the direct real-model runs.

[test_run_A1_smoke_20261001_090052.log](tests/test_run_A1_smoke_20261001_090052.log)

[test_run_A1_smoke_20261001_090116_retry1.log](tests/test_run_A1_smoke_20261001_090116_retry1.log)

[test_run_A1_smoke_20261001_152814.log](tests/test_run_A1_smoke_20261001_152814.log)

[test_run_A1_smoke_20261001_152814_retry1.log](tests/test_run_A1_smoke_20261001_152814_retry1.log)

[test_run_A1_smoke_20261001_152814_retry2.log](tests/test_run_A1_smoke_20261001_152814_retry2.log)

[test_run_A2_unit_20261001_095313.log](tests/test_run_A2_unit_20261001_095313.log)

[test_run_A2_unit_20261001_1530.log](tests/test_run_A2_unit_20261001_1530.log)

[test_run_A3_integration_20261001_095322.log](tests/test_run_A3_integration_20261001_095322.log)

[test_run_A3_integration_20261001_095611.log](tests/test_run_A3_integration_20261001_095611.log)

[test_run_A3_integration_20261001_1530.log](tests/test_run_A3_integration_20261001_1530.log)

[test_run_B1_smoke_20261001_095330.log](tests/test_run_B1_smoke_20261001_095330.log)

[test_run_B1_smoke_20261001_1530.log](tests/test_run_B1_smoke_20261001_1530.log)

[test_run_B2_unit_20261001_095337.log](tests/test_run_B2_unit_20261001_095337.log)

[test_run_B2_unit_20261001_1530.log](tests/test_run_B2_unit_20261001_1530.log)

[test_run_B3_integration_20261001_095343.log](tests/test_run_B3_integration_20261001_095343.log)

[test_run_B3_integration_20261001_101632.log](tests/test_run_B3_integration_20261001_101632.log)

[test_run_B3_integration_20261001_1530.log](tests/test_run_B3_integration_20261001_1530.log)

[test_run_pbi11_A1_smoke_20261001_172551.log](tests/test_run_pbi11_A1_smoke_20261001_172551.log)

[test_run_pbi11_A2_unit_20261001_172551.log](tests/test_run_pbi11_A2_unit_20261001_172551.log)

[test_run_pbi11_A3_integration_20261001_172551.log](tests/test_run_pbi11_A3_integration_20261001_172551.log)

[test_run_pbi11_B1_smoke_20261001_172551.log](tests/test_run_pbi11_B1_smoke_20261001_172551.log)

[test_run_pbi11_B2_unit_20261001_172551.log](tests/test_run_pbi11_B2_unit_20261001_172551.log)

[test_run_pbi11_B3_integration_20261001_172551.log](tests/test_run_pbi11_B3_integration_20261001_172551.log)

[test_run_pbi18_A1_smoke_20261001_172200.log](tests/test_run_pbi18_A1_smoke_20261001_172200.log)

[test_run_pbi18_A2_unit_20261001_172200.log](tests/test_run_pbi18_A2_unit_20261001_172200.log)

[test_run_pbi18_A3_integration_20261001_172200.log](tests/test_run_pbi18_A3_integration_20261001_172200.log)

[test_run_pbi18_B1_smoke_20261001_172200.log](tests/test_run_pbi18_B1_smoke_20261001_172200.log)

[test_run_pbi18_B2_unit_20261001_172200.log](tests/test_run_pbi18_B2_unit_20261001_172200.log)

[test_run_pbi18_B3_integration_20261001_172200.log](tests/test_run_pbi18_B3_integration_20261001_172200.log)

[test_run_pbi3_A1_smoke_20261001_1552.log](tests/test_run_pbi3_A1_smoke_20261001_1552.log)

[test_run_pbi3_A1_smoke_20261001_171053.log](tests/test_run_pbi3_A1_smoke_20261001_171053.log)

[test_run_pbi3_A2_unit_20261001_1552.log](tests/test_run_pbi3_A2_unit_20261001_1552.log)

[test_run_pbi3_A2_unit_20261001_171053.log](tests/test_run_pbi3_A2_unit_20261001_171053.log)

[test_run_pbi3_A3_integration_20261001_1552.log](tests/test_run_pbi3_A3_integration_20261001_1552.log)

[test_run_pbi3_A3_integration_20261001_171053.log](tests/test_run_pbi3_A3_integration_20261001_171053.log)

[test_run_pbi3_B1_smoke_20261001_1552.log](tests/test_run_pbi3_B1_smoke_20261001_1552.log)

[test_run_pbi3_B1_smoke_20261001_171053.log](tests/test_run_pbi3_B1_smoke_20261001_171053.log)

[test_run_pbi3_B2_unit_20261001_1552.log](tests/test_run_pbi3_B2_unit_20261001_1552.log)

[test_run_pbi3_B2_unit_20261001_171053.log](tests/test_run_pbi3_B2_unit_20261001_171053.log)

[test_run_pbi3_B3_integration_20261001_1552.log](tests/test_run_pbi3_B3_integration_20261001_1552.log)

[test_run_pbi3_B3_integration_20261001_171053.log](tests/test_run_pbi3_B3_integration_20261001_171053.log)

[test_run_pbi4_A1_smoke_20261001_171356.log](tests/test_run_pbi4_A1_smoke_20261001_171356.log)

[test_run_pbi4_A2_unit_20261001_171356.log](tests/test_run_pbi4_A2_unit_20261001_171356.log)

[test_run_pbi4_A3_integration_20261001_171356.log](tests/test_run_pbi4_A3_integration_20261001_171356.log)

[test_run_pbi4_B1_smoke_20261001_171356.log](tests/test_run_pbi4_B1_smoke_20261001_171356.log)

[test_run_pbi4_B2_unit_20261001_171356.log](tests/test_run_pbi4_B2_unit_20261001_171356.log)

[test_run_pbi4_B3_integration_20261001_171356.log](tests/test_run_pbi4_B3_integration_20261001_171356.log)

[test_run_pbi5_A1_smoke_20261001_171904.log](tests/test_run_pbi5_A1_smoke_20261001_171904.log)

[test_run_pbi5_A2_unit_20261001_171904.log](tests/test_run_pbi5_A2_unit_20261001_171904.log)

[test_run_pbi5_A3_integration_20261001_171904.log](tests/test_run_pbi5_A3_integration_20261001_171904.log)

[test_run_pbi5_B1_smoke_20261001_171904.log](tests/test_run_pbi5_B1_smoke_20261001_171904.log)

[test_run_pbi5_B2_unit_20261001_171904.log](tests/test_run_pbi5_B2_unit_20261001_171904.log)

[test_run_pbi5_B3_integration_20261001_171904.log](tests/test_run_pbi5_B3_integration_20261001_171904.log)

[test_run_evidence_move_A1_smoke_20261001_191913.log](tests/test_run_evidence_move_A1_smoke_20261001_191913.log)

[test_run_evidence_move_A2_unit_20261001_191913.log](tests/test_run_evidence_move_A2_unit_20261001_191913.log)

[test_run_evidence_move_A3_integration_20261001_191913.log](tests/test_run_evidence_move_A3_integration_20261001_191913.log)

[test_run_evidence_move_B1_smoke_20261001_191913.log](tests/test_run_evidence_move_B1_smoke_20261001_191913.log)

[test_run_evidence_move_B2_unit_20261001_191913.log](tests/test_run_evidence_move_B2_unit_20261001_191913.log)

[test_run_evidence_move_B3_integration_20261001_191913.log](tests/test_run_evidence_move_B3_integration_20261001_191913.log)

[test_run_pbi18_languages_A1_smoke_20261001_210803.log](tests/test_run_pbi18_languages_A1_smoke_20261001_210803.log)

[test_run_pbi18_languages_A2_unit_20261001_210803.log](tests/test_run_pbi18_languages_A2_unit_20261001_210803.log)

[test_run_pbi18_languages_A3_integration_20261001_210803.log](tests/test_run_pbi18_languages_A3_integration_20261001_210803.log)

[test_run_pbi18_languages_B1_smoke_20261001_210803.log](tests/test_run_pbi18_languages_B1_smoke_20261001_210803.log)

[test_run_pbi18_languages_B2_unit_20261001_210803.log](tests/test_run_pbi18_languages_B2_unit_20261001_210803.log)

[test_run_pbi18_languages_B3_integration_20261001_210803.log](tests/test_run_pbi18_languages_B3_integration_20261001_210803.log)

[test_run_pbi6_A1_smoke_20261001_210446.log](tests/test_run_pbi6_A1_smoke_20261001_210446.log)

[test_run_pbi6_A2_unit_20261001_210446.log](tests/test_run_pbi6_A2_unit_20261001_210446.log)

[test_run_pbi6_A3_integration_20261001_210446.log](tests/test_run_pbi6_A3_integration_20261001_210446.log)

[test_run_pbi6_B1_smoke_20261001_210446.log](tests/test_run_pbi6_B1_smoke_20261001_210446.log)

[test_run_pbi6_B2_unit_20261001_210446.log](tests/test_run_pbi6_B2_unit_20261001_210446.log)

[test_run_pbi6_B3_integration_20261001_210446.log](tests/test_run_pbi6_B3_integration_20261001_210446.log)

[test_run_pbi6_draft_A1_smoke_20261001_193213.log](tests/test_run_pbi6_draft_A1_smoke_20261001_193213.log)

[test_run_pbi6_draft_A2_unit_20261001_193213.log](tests/test_run_pbi6_draft_A2_unit_20261001_193213.log)

[test_run_pbi6_draft_A3_integration_20261001_193213.log](tests/test_run_pbi6_draft_A3_integration_20261001_193213.log)

[test_run_pbi6_draft_B1_smoke_20261001_193213.log](tests/test_run_pbi6_draft_B1_smoke_20261001_193213.log)

[test_run_pbi6_draft_B2_unit_20261001_193213.log](tests/test_run_pbi6_draft_B2_unit_20261001_193213.log)

[test_run_pbi6_draft_B3_integration_20261001_193213.log](tests/test_run_pbi6_draft_B3_integration_20261001_193213.log)

[test_run_pbi18_languages_final_A1_smoke_20261001_211557.log](tests/test_run_pbi18_languages_final_A1_smoke_20261001_211557.log)

[test_run_pbi18_languages_final_A2_unit_20261001_211557.log](tests/test_run_pbi18_languages_final_A2_unit_20261001_211557.log)

[test_run_pbi18_languages_final_A3_integration_20261001_211557.log](tests/test_run_pbi18_languages_final_A3_integration_20261001_211557.log)

[test_run_pbi18_languages_final_B1_smoke_20261001_211557.log](tests/test_run_pbi18_languages_final_B1_smoke_20261001_211557.log)

[test_run_pbi18_languages_final_B2_unit_20261001_211557.log](tests/test_run_pbi18_languages_final_B2_unit_20261001_211557.log)

[test_run_pbi18_languages_final_B3_integration_20261001_211557.log](tests/test_run_pbi18_languages_final_B3_integration_20261001_211557.log)

[test_run_pbi6_final_A1_smoke_20261001_211415.log](tests/test_run_pbi6_final_A1_smoke_20261001_211415.log)

[test_run_pbi6_final_A2_unit_20261001_211415.log](tests/test_run_pbi6_final_A2_unit_20261001_211415.log)

[test_run_pbi6_final_A3_integration_20261001_211415.log](tests/test_run_pbi6_final_A3_integration_20261001_211415.log)

[test_run_pbi6_final_B1_smoke_20261001_211415.log](tests/test_run_pbi6_final_B1_smoke_20261001_211415.log)

[test_run_pbi6_final_B2_unit_20261001_211415.log](tests/test_run_pbi6_final_B2_unit_20261001_211415.log)

[test_run_pbi6_final_B3_integration_20261001_211415.log](tests/test_run_pbi6_final_B3_integration_20261001_211415.log)

[test_run_pbi6_retry_A1_smoke_20261001_211249.log](tests/test_run_pbi6_retry_A1_smoke_20261001_211249.log)

[test_run_pbi6_retry_A2_unit_20261001_211249.log](tests/test_run_pbi6_retry_A2_unit_20261001_211249.log)

[test_run_pbi6_retry_A3_integration_20261001_211249.log](tests/test_run_pbi6_retry_A3_integration_20261001_211249.log)

[test_run_pbi11_fr11_final_A1_smoke_20261001_213621.log](tests/test_run_pbi11_fr11_final_A1_smoke_20261001_213621.log)

[test_run_pbi11_fr11_final_A2_unit_20261001_213621.log](tests/test_run_pbi11_fr11_final_A2_unit_20261001_213621.log)

[test_run_pbi11_fr11_final_A3_integration_20261001_213621.log](tests/test_run_pbi11_fr11_final_A3_integration_20261001_213621.log)

[test_run_pbi11_fr11_final_B1_smoke_20261001_213621.log](tests/test_run_pbi11_fr11_final_B1_smoke_20261001_213621.log)

[test_run_pbi11_fr11_final_B2_unit_20261001_213621.log](tests/test_run_pbi11_fr11_final_B2_unit_20261001_213621.log)

[test_run_pbi11_fr11_final_B3_integration_20261001_213621.log](tests/test_run_pbi11_fr11_final_B3_integration_20261001_213621.log)

## Polish multi-person meeting correction — 2026-10-02

The Product Owner rejected the FLEURS sentences as meeting evidence. The
[official Sejm committee fixture](polish_sejm_meeting_fixture.md) is a real
Polish multi-person sitting, with recording and official written record from
the same meeting. A 600-second excerpt was staged outside Git. The official
record names the chair, presenter, and a later presenter; it is not a
time-aligned ASR reference. The [compact run capture](tests/polish_sejm_meeting_run_20261002.json)
holds source URLs, SHA-256, record ID, model identity, counts, and the
observed minutes failure.

The intended test was to transcribe a real Polish meeting, label its
speakers, persist a source-checked chair name, and attempt draft minutes.
Direct `swift run` commands from the repository root used Parakeet v3 for
`--language pl` and the same Fluid diarizer used on AMI. The transcript
record `CA95C7AB-695E-4501-9176-938F0D463DFC` has 802 timed segments
over the 10-minute media. Diarization assigned S1, S2, and S3, beginning
at approximately 108, 222, and 582 seconds; 0 weak-audio warnings were
saved. The first S1 turn matches the chair's opening in the official record,
so the manual `recognize name` action persisted `S1 = Ryszard Petru`. This
does not independently prove every S1 segment belongs to him. The S2
segment begins at the minister's presentation, and S3 begins near the
later presenter. This verifies multiple meeting voices in the source and
the prototype's multi-label path, while leaving diarization accuracy
unscored.

The initial `summarize --summarizer mlx` attempt on this record returned
status 2 and `Unknown source segment: S1`. `S1` was a speaker label, not a
source segment ID. The MLX adapter now marks IDs explicitly and retries once
when the model cites an invalid ID. The core minutes path now clears an
action owner unless its cited segments contain that speaker. A focused
regression test proved the strict citation rejection and owner guard. The
six Sprint gates passed after the repair; their logs are linked below.

A direct rerun on the same Sejm record exited 0 and saved four draft items:
a summary, one decision, one action, and one open question. The decision
about the positive opinion at about 540–553 seconds is supported by the
cited transcript. The action labels the chair's request for a presenter as
a future action, and the open question is absent from its cited 288–296
second range. This is a **content-quality failure** despite the repaired
structural path. The draft is not publishable, and the Product Owner has
said the increment is not ready for delivery. The official PDF was used
for a [passage-level transcription review](tests/polish_sejm_pdf_transcription_review_20261002.md):
the main turns, several amounts, and the positive-opinion decision are
recognizable, but names, acronyms, words, and numerical units have errors
needing human correction. The PDF is edited and not time aligned, so no
whole-clip word error rate is claimed. The
earlier FLEURS scores remain a separate single-speaker language feasibility
result, not a Polish meeting validation result.

A further prompt experiment asked the model to cite the summary. On the
same record it changed to English and added unsupported budget details.
That prompt was reverted; the final adapter uses `minutes-v2` and the
repaired structural guards. This failed experiment strengthens the
minutes-model quality concern rather than providing a validated fix.

[Sprint 2 Sejm fix A1 smoke](tests/test_run_sejm_minutes_fix_A1_smoke_20261002_114813.log),
[A2 unit](tests/test_run_sejm_minutes_fix_A2_unit_20261002_114813.log),
[A3 integration](tests/test_run_sejm_minutes_fix_A3_integration_20261002_114813.log),
[B1 smoke](tests/test_run_sejm_minutes_fix_B1_smoke_20261002_114813.log),
[B2 unit](tests/test_run_sejm_minutes_fix_B2_unit_20261002_114813.log), and
[B3 integration](tests/test_run_sejm_minutes_fix_B3_integration_20261002_114813.log)
all passed on 2026-10-02.

After reverting the unsuccessful summary-citation prompt, the final code
passed all six gates again: [A1](tests/test_run_sejm_minutes_final_A1_smoke_20261002_121315.log),
[A2](tests/test_run_sejm_minutes_final_A2_unit_20261002_121315.log),
[A3](tests/test_run_sejm_minutes_final_A3_integration_20261002_121315.log),
[B1](tests/test_run_sejm_minutes_final_B1_smoke_20261002_121315.log),
[B2](tests/test_run_sejm_minutes_final_B2_unit_20261002_121315.log), and
[B3](tests/test_run_sejm_minutes_final_B3_integration_20261002_121315.log).

Two loose root-level JSON output snapshots were moved into this test
evidence directory: the [15-segment Polish FLEURS read-speech
record](tests/6CF1F770-541E-4171-BBD3-8469FD98CD42.json) and the
[2,576-segment AMI English meeting
record](tests/74E58D9D-783C-4069-A7F1-1F08468128E3.json).
They are archived outputs from earlier runs, not the Sejm meeting fixture
and not substitutes for the real-model run capture above.

## DOE 30-minute English meeting and second minutes model — 2026-10-02

The Product Owner asked for a longer English public meeting comparable to
the Sejm source. The [U.S. Department of Energy ITIAC Day 2
fixture](doe_itiac_day2_fixture.md) has an official recording link and a
speaker-labeled transcript. A 30-minute audio excerpt was staged outside
Git and verified by duration and SHA-256. The [run
capture](tests/doe_itiac_day2_run_20261002.json) records the source,
hash, record UUID, model, observed counts, and minutes errors.

Direct CLI inference on this real audio saved record
`36237678-66EB-456D-897A-4687BF33F390` with 4,216 timed English
segments. Fluid diarization assigned eight anonymous IDs and no
low-audio warnings. The opening transcript matches DOE's written record:
S1 begins with Zachary Pritchard at about 3 seconds, S3 begins with
Sharon Nolen at about 128 seconds, and S5 begins near Sue's question at
about 852 seconds. These are turn-level checks, not a scored cluster
identity or whole-excerpt WER result.

The 4B Qwen minutes attempt on the full 30-minute record exited 2 with
`The data couldn’t be read because it isn’t in the correct format.` The
7B Qwen2.5 attempt on a separate copy of the same record also exited 2,
with `The data couldn’t be read because it is missing.` Both stores retained
zero review items. The errors are consistent with model output failing the
expected structured JSON schema; raw model responses were not retained, so
the exact malformed fields are not claimed. This is a long-input minutes
failure for both candidates, while the ASR and diarization path completed.

The same 7B model did return structured output on the ten-minute Sejm
record, but its cited decision range ended before the actual decision and
its action mislabeled a transition to the next agenda item. The summary
switched to English. The [benchmark](ami_asr_benchmark.md#polish-meeting-minutes-quality-check)
interprets that controlled comparison and the product impact.

## Product Owner presentation rehearsal — 2026-10-02

The final presentation was rehearsed on the two real multi-person meetings
using a fresh local store. The saved [full AMI
record](tests/43CE873A-603C-473F-9B23-A785A0689456.json) has 2,582 timed
segments, S1–S3, 16 weak-audio warnings, and one deliberately invented
manual alias on S2. Its first warning spans 19.32–20.36 seconds for S3. The
saved [Sejm record](tests/5DC83D71-D1B0-4568-A66D-70F3B9A71D46.json) has
801 segments, S1–S3, no warnings, no assigned names, and four draft items.
The [short AMI minutes record](tests/4395B92A-60B8-4B8C-9A20-3AE37642FE92.json)
has 217 segments, no assigned names, and three draft items. The invented
alias was not supplied to either minutes run.

The Sejm draft contains a supported positive-opinion decision and also an
action that misclassifies a request to present, an invented question, and an
uncited summary. The English draft adds unsupported remote-control and
setup interpretations and has an uncited summary. This fresh run confirms
the existing minutes-content blocker. Direct debug-binary summarization
aborted with an adapter `NSRangeException` for both saved records; the same
records were then summarized successfully using the documented `swift run`
entry point. The launcher difference remains unexplained and is not counted
as a direct-binary pass. No additional claim of minutes quality or sprint
acceptance follows from this rehearsal.

## Evidence-first minutes and response gate — 2026-10-02

The approved recovery design adds a ten-minute minutes-input limit, exact
quotation and citation checks, and two bounded repair prompts when a model
returns malformed JSON or invalid evidence. Controlled Swift Testing cases
cover malformed JSON, unknown source IDs, uncited quotations, schema errors,
and rejection after the second repair. Focused core and integration tests
cover valid cited output, an over-limit recording, and preservation of the
transcript after a malformed model response. These focused tests passed;
the full six-gate rerun passed on 2026-10-02 under stamp
`20261002_155412`. The logs are [A1 smoke](tests/test_run_evidence_gate_A1_smoke_20261002_155412.log),
[A2 unit](tests/test_run_evidence_gate_A2_unit_20261002_155412.log),
[A3 integration](tests/test_run_evidence_gate_A3_integration_20261002_155412.log),
[B1 smoke](tests/test_run_evidence_gate_B1_smoke_20261002_155412.log),
[B2 unit](tests/test_run_evidence_gate_B2_unit_20261002_155412.log), and
[B3 integration](tests/test_run_evidence_gate_B3_integration_20261002_155412.log).
Final documentation reconciliation remains pending.

Real-model trials have **not** passed content review. On a 120-second AMI
excerpt, Qwen3-4B first returned the wrong summary shape. After prompt and
repair changes it produced parseable evidence JSON, but chose an
introduction as its summary. On the ten-minute Sejm excerpt, the 4B model
cited four chunks where at most two were allowed and gave a decision quote
that extended beyond its cited chunk. Qwen2.5-7B summarized only the
opening greeting. On a six-chunk Sejm decision window, 4B still failed
technical validation after two repair prompts; 7B found decision wording
but cited too little of the quote and likewise failed bounded repair.
The validator correctly withholds these drafts. The 30B local candidate
was [downloaded and hash-checked](tests/qwen3_30b_download_20261003.md)
and then [run on the same saved AMI and Sejm transcripts](tests/qwen3_30b_minutes_trial_20261003.md)
on 2026-10-03. AMI produced one source-exact brief quotation after one
citation repair, with no decision, action, or question. Sejm produced
the same malformed JSON on all three attempts and saved zero items;
the proposed decision quote also cited only the first of two required
source chunks. The trial records exact outputs, elapsed time, maximum
resident set size, failure preservation, and manual source assessment.
This is a real-model quality failure for the larger candidate, not a
controlled-test pass for useful minutes.

The adapter was rebuilt after Xcode's Metal toolchain path changed; a
clean Swift build and `swift test --package-path experiments/MinutesAdapter`
passed all four focused response-validation cases. The full Sprint 2
wrapper then passed A1, A2, A3, B1, B2, and B3 on 2026-10-03 at stamp
`20261003_143640`: [A1](tests/test_run_qwen3_30b_final_A1_smoke_20261003_143640.log),
[A2](tests/test_run_qwen3_30b_final_A2_unit_20261003_143640.log),
[A3](tests/test_run_qwen3_30b_final_A3_integration_20261003_143640.log),
[B1](tests/test_run_qwen3_30b_final_B1_smoke_20261003_143640.log),
[B2](tests/test_run_qwen3_30b_final_B2_unit_20261003_143640.log), and
[B3](tests/test_run_qwen3_30b_final_B3_integration_20261003_143640.log).
These tests verify contracts and failure preservation; they do not
override the manual minutes-quality failure.

## Staged minutes and transcript correction experiment — 2026-10-04

The approved PBI-011.5 repair now has a reversible transcript reading
layer, isolated-fragment proposals, audio-reviewed operator text
corrections, topic assignment, per-topic summaries, extracted-item
validation, and atomic failure preservation. `MultiStageTests` checks
raw-segment conservation, multi-fragment speaker continuity, complete
topic assignment, retention of an extracted item's originating topic,
and reversible operator corrections. The integration suite checks the
CLI correction path and that a failed model response leaves the record
intact. The adapter's `PipelineValidationTests` checks invalid JSON,
unknown or duplicate IDs, exact excerpts, bounded shortening of a
near-miss quote, candidate type signals, and topic citation
reconciliation. `swift test` passed 13 integration and 18 core tests;
`swift test -c release --skip-build --filter PipelineValidationTests`
passed its focused case after the release adapter build.

The same saved 120-second AMI and approximately ten-minute Sejm ASR
records were then run through the real local 30B staged pipeline. The
[controlled trial report](tests/multistage_minutes_trial_20261004.md)
provides inputs, final runtime and memory, all stage responses, the saved
draft records, and a manual claim-level source audit. Both final runs
passed technical source and coverage gates: 217/217 raw segments and
21/21 reading utterances on AMI; 801/801 raw segments and 32/32 reading
utterances on Sejm. Only 2/5 AMI and 2/4 Sejm topic summaries were fully
supported by their own cited ASR utterances. The Sejm run found one of
two explicit decisions in the saved excerpt. These content results are
**FAIL** for dependable minutes; a technical pass does not override them.

The full Sprint 2 runner passed all six prescribed gates under stamp
`20261004_103418`: [A1 smoke](tests/test_run_staged_minutes_final_A1_smoke_20261004_103418.log),
[A2 unit](tests/test_run_staged_minutes_final_A2_unit_20261004_103418.log),
[A3 integration](tests/test_run_staged_minutes_final_A3_integration_20261004_103418.log),
[B1 smoke](tests/test_run_staged_minutes_final_B1_smoke_20261004_103418.log),
[B2 unit](tests/test_run_staged_minutes_final_B2_unit_20261004_103418.log),
and [B3 integration](tests/test_run_staged_minutes_final_B3_integration_20261004_103418.log).
The tests verify implementation contracts and non-destructive failure
behavior; they do not establish factual minutes quality or Product Owner
acceptance. The quality blocker remains open.
