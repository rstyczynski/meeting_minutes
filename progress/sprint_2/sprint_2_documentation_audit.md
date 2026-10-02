# Sprint 2 — Documentation reconciliation gate

Status: PBI-011.1 through PBI-011.5 and PBI-018 passed their individual audits and local completion commits. This records the PBI-011 parent reconciliation required by P8 of the local RUP patch. The board marks all Sprint 2 items tested and the sprint implemented; the final sprint documentation review remains open.

The Product Owner's durable [preferences](../../RUPStrikesBack.patch/USER_PREFERENCES.md) require narrative paragraphs rather than Markdown tables; the method-defined [progress board](../../PROGRESS_BOARD.md) remains a four-column table. Each sprint-tracked child PBI receives its own verification, reconciliation, and local completion commit. No remote push is authorized.

## PBI-011.1 completion record

The core and store child passed its six RUP gates, fresh-process IT-1 reload, build, local-link check, and git diff --check. The first A1 attempt failed at SwiftPM's nested sandbox; its retry passed. The audit attributed shared work to later children without marking them complete. Its local completion commit is 72fb8d4. Exact historical gate logs are named in [the functional test record](sprint_2_tests.md).

## PBI-011.2 pre-commit reconciliation — 2026-10-01

The Product Owner approved the separate transcribe, optional recognize, and optional summarize CLI amendment on 2026-10-01. The Test Architect added SM-2, UT-7 through UT-9, and IT-7 through IT-9 skeletons and manifest entries before the constructor implemented the change. This approved contract supersedes the original combined-import flow for the active prototype. The old import route remains for test compatibility. No new Product Owner design decision is pending for this child.

The root [SRS](../../docs/srs.md) states the three capabilities, neutral-label summary, chair correction, optional automatic name suggestions beyond the MVP, and FR-09/FR-10 low-quality-audio behavior. Its FR-11 bilingual aspiration is preserved without claiming Sprint 2 validation. The [architecture](../../docs/architecture.md) now describes independent commands through MeetingCore and local adapters. The [test profile](../../docs/test-profile.md) maps them to the actual smoke, unit, integration, and operational checks; it records Swift Testing as the accepted package after Xcode installation. These durable artifacts agree with the implemented interface.

[Sprint setup](sprint_2_setup.md) records why the Sprint 1 baseline may need a targeted later review and now notes the accepted CLI amendment. The [design](sprint_2_design.md) and [accepted change record](sprint_2_proposedchanges.md) define the commands and test cases. The [implementation record](sprint_2_implementation.md) states code artifacts and status for every child, provides a model-free synthetic sequence, local-model prerequisites and options, exact working commands, expected result, cat/jq human rendering, and an error case. The [functional test record](sprint_2_tests.md) gives expected and observed outcomes and the current gate logs. The [README](../../README.md) now directs a reader to that walkthrough and the decision-facing [benchmark](ami_asr_benchmark.md). The [fixture record](ami_es2002a_fixture.md) supplies the real meeting's license, sources, hashes, and participant mapping. The [progress board](../../PROGRESS_BOARD.md) marks only PBI-011.1 and PBI-011.2 tested within the active Sprint 2 rows; Sprint 3 remains Planned.

The CLI source, core recognition/summarization contracts, settings, Fluid adapter, and SwiftUI player compile. The synthetic copy-paste sequence was executed exactly as documented and produced record 2CB4730A-E87B-4DEE-A871-4EF99C565E03. Its formatted cat/jq output showed five timed turns, speaker_2 named Ada, the corrected first turn, and four review items with expected citations and owner. The documented missing-media command printed Media file does not exist and exited 2. A real Fluid transcription and recognition saved anonymous labels and 16 warnings. A local MLX run persisted synthetic and natural-audio minutes; the natural content failed quality, which is plainly reported rather than counted as a validated product result.

The root swift build passed. The direct swift test run passed 18 tests, nine core and nine integration. For this child, new-work A1, A2, A3 and full-regression B1, B2, B3 passed in timestamped logs named in the functional test record. The first A1 attempt failed before assertions due to the nested SwiftPM sandbox. Its outside-sandbox retry found a real smoke mismatch: help omitted the supported import route. After correcting CLI help, the second retry passed. The two failed logs are retained with the successful logs. The generated MLX shader library and local model checks are experiment evidence; they do not turn the natural minutes content into a pass.

A fresh check of 13 Markdown files in README, docs, and Sprint 2 found zero broken local links. No narrative Markdown tables were found; the progress board remains the mandatory table. git diff --check passed. The board's PBI-011.2 row is consistent with the six successful gates, accepted design, implemented commands, and verified user instructions. No Plan or backlog status was changed.

The first completion commit after PBI-011.1 will include shared recognition, summarization, review-player, experiment, test, and benchmark changes already developed alongside the CLI. This audit attributes them to PBI-011.3 through PBI-011.5 and PBI-018 without claiming those items complete. Their remaining checks are a bounded review-player replay, fresh per-child gates and audits, warning and minutes quality interpretation, and explicit Sprint 3 architecture analysis. A failing natural minutes result is an architectural finding and blocks any claim of trustworthy generated minutes, not the completed CLI-interface child.

## PBI-011.3 pre-commit reconciliation — 2026-10-01

The preceding PBI-011.2 completion commit is 5c5a7bf and contains the shared fixture, correction, adapter, test, and benchmark code that PBI-011.3 uses. This child now has independent acceptance evidence. The root SRS still requires timed transcript, speaker correction, and cited minutes; the architecture still assigns these contracts to MeetingCore and the local record. The test profile still maps smoke, unit, and integration to tests/run.sh. Sprint setup and the accepted design assign the fixture and correction child to Sprint 2 after the core and CLI children. The test specification names synthetic generation, source resolution, reload, and correction checks.

The implementation record was corrected to report the fresh regeneration and gate outcome. The functional test record now gives the generator's observed format and six new log names. The checked-in tests/fixtures/README.md supplies regeneration instructions and explicitly distinguishes invented speech from natural-model evidence. The README directs users to the verified CLI walkthrough; that walkthrough was executed in the prior audit and its cat/jq output showed five turns, the Ada name assignment, the moved first turn, and cited review items. The AMI benchmark remains a separate PBI-018 measurement and is not counted as a fixture quality claim. The progress board now marks PBI-011.3 tested while the parent and other children remain under construction.

For this child, the generator copied to /private/tmp/meeting-fixture-regenerate-pbi3 produced a new 16 kHz mono 16-bit PCM WAV lasting 16.727 seconds and a paired reference with five turns. The checked-in fixture was not overwritten. All six prescribed tests passed in the timestamped pbi3 A1/A2/A3/B1/B2/B3 logs recorded in the functional test record. The earlier root swift build and swift test (18 passing tests) remain valid because this child made no code change after them. A fresh local-link check found zero broken links across 13 README/docs/Sprint 2 Markdown files; narrative documents still have no tables, and the progress board retains its canonical four columns. git diff --check passed before this audit.

The review player, local-model integration, benchmark interpretation, and Sprint 2 parent are not advanced by this child. Bounded audio replay remains untested after the user closed the preview, and natural MLX minutes still fail content quality. Those facts are visible in the implementation and test records. This child has no unresolved design approval and is ready for its own local completion commit.

The Product Owner then requested one main test wrapper to avoid repeated permissions. tests/run-sprint-gates.sh was added, made executable, and passed bash -n. It validates its Sprint directory and log label, executes all six tests/run.sh gates in the required order, stops at the first failure, and writes distinct timestamped logs. The test profile, README, implementation record, and functional test record now name this entry point. It ran successfully for PBI-011.3 with stamp 20261001_171053; all six logs ended in PASS. Its command prefix was approved once for future outside-sandbox use. This is a process usability improvement within the child completion work, not a change to the required gate definitions.

## PBI-011.4 pre-commit reconciliation — 2026-10-01

PBI-011.3 was completed in local commit 1bae555. The SRS and architecture continue to require one shared record, source-linked review, and a macOS SwiftUI adapter. Sprint setup assigns the review-player child after the core, CLI, and fixture work; the accepted design requires a macOS build, opening a CLI-created record by ID, manual local source seeking, and a synthetic record-opening integration test. The test profile routes those checks through the six-level runner plus the manual operational check. No new design change or Product Owner decision was introduced for this child.

The implementation record and functional test record were updated with the actual AVKit crash, AVFoundation replacement, real-record open and seek, and the Product Owner's instruction to close the preview after continuous playback became disruptive. The README points to these records and does not claim a production-ready player. The AMI benchmark reports the source-review evidence and its FR-10 limits. The progress board now marks PBI-011.4 tested while PBI-011.5, PBI-018, the parent, and Sprint 2 remain under construction. The SRS, architecture, test profile, Sprint setup, accepted design, implementation, tests, README, board, and benchmark were checked against the executable behavior.

The manual app run loaded the real AMI record, displayed its transcript and 16 warnings, sought the first warning at 19.3 seconds, and sought a transcript range at 4.7 seconds. The review app built after the bounded-pause edit, and the integration test still opens a CLI-created record. The single wrapper ran all six pbi4 gates successfully with stamp 20261001_171356; their exact log names are in the functional test record. The user closed the preview, and it has not been reopened. Therefore the range seeking and accepted child criterion are verified, while the newly added automatic pause has only build coverage and is explicitly left as a follow-up check. No sentence in the Product Owner evidence treats that pause as manually verified.

A fresh local-link check found zero broken links in the 13 README/docs/Sprint 2 Markdown files. Narrative documents contain no tables, while the progress board keeps its four-column table. git diff --check passed. The limitation on post-change playback is visible and does not invalidate the completed build/open/seek criterion. This child is ready for its local completion commit; local-model and benchmark children retain their separate gates and audits.

## PBI-011.5 pre-commit reconciliation — 2026-10-01

PBI-011.4 was completed in local commit aafa38e. The root SRS and architecture continue to require replaceable local transcription, recognition, and minutes adapters through MeetingCore. The test profile specifies synthetic contracts and applicable operational checks. Sprint setup and the accepted design assign both selectable ASR backends, Fluid diarization, and MLX minutes to PBI-011.5, with pinned revisions, local-only execution, and timestamp/source evidence or explicit blocked outcomes. The test specification does not equate a fixture-derived result with natural-meeting model quality.

The implementation record now gives the exact pinned MLX Swift LM and MLX Swift package versions, Qwen model revision and SHA-256, staged paths, working build commands, manual metallib packaging step, settings keys, and the real and synthetic saved-record IDs. The functional test record names the MLX offline run and six pbi5 gate logs. The benchmark report includes the same model identity, source-linked invented output, natural AMI failure, and local-only evidence. The README points to these decision-facing records; the SRS, architecture, test profile, Sprint setup, design, implementation, tests, README, benchmark, and progress board were reconciled against the actual executable behavior. The board now marks PBI-011.5 tested while PBI-018 and the Sprint parent remain under construction.

The root package built; the MLX adapter release build passed with the documented package-path command. Xcode 27 built default.metallib, which was copied next to the executable. The Qwen model.safetensors file was 2,263,022,417 bytes with SHA-256 2a73c6c248601ab904e035548abd8e6abb65ea27dcb5f342fb0a8910eb44173f. Fluid and whisper ASR, Fluid diarization, and MLX minutes each ran from local staged paths. The separate MLX network-denial run exited 0 and produced parseable, cited synthetic minutes. The full AMI headset record and 120-second minutes record supply timestamped transcript and source evidence. All six pbi5 gate logs with stamp 20261001_171904 passed through the single wrapper. The natural minutes still invent commitments and questions, so content quality is explicitly failed. This child proves adapter feasibility and records the quality risk for PBI-018 and Sprint 3; it does not recommend this model for unattended minutes.

A fresh check found zero broken local links in the 13 README/docs/Sprint 2 Markdown files. Narrative documents remain paragraphs without Markdown tables, while the board retains its required four columns. git diff --check passed. The manual metallib copy is a portability limitation; Xcode's xcrun metal lookup is still anomalous even though the direct compiler and MLX build worked. There is no pending design approval for this child. Its technical integration acceptance and gate evidence are ready for a local completion commit.

## PBI-018 pre-commit reconciliation — 2026-10-01

PBI-011.5 was completed in local commit b70ef21. The root SRS and architecture identify offline transcription, attribution, local minutes, and low-quality-audio risks. The test profile requires synthetic contracts plus operational validation on approved local media. Sprint setup, the accepted design, and the root backlog assign PBI-018 a general benchmark purpose: compare architecturally significant options on common test data with explicit quality and resource measures, preserve reproducibility and limits, and leave evidence-based architecture decisions for Sprint 3. The test specification separates deterministic fixture contracts from natural-meeting quality. These sources agree with the benchmark's measured scope.

The benchmark report now states Sprint 2 measurement complete and has a Product Owner summary, compared model identities, official AMI provenance, common-input and alternate-input results, resource repeats, model size, timestamp diagnostics, speaker attribution, warning coverage and spillover, local-only execution, MLX minutes quality failure, license information, commands, raw evidence paths, limits, and a PBI-018 acceptance assessment. The implementation record and functional test record were corrected to cite reproducible results and the six current gate logs. The README links directly to the report and user walkthrough. The progress board now marks PBI-018 tested; it does not mark the parent or Sprint complete yet. The SRS, architecture, test profile, Sprint setup, design, implementation, functional tests, README, benchmark, fixture record, and board were reconciled against the evidence.

All four ASR WER scores were rerun from saved hypotheses against the same 2,633-token manual reference and matched the report: Fluid headset 0.1948, whisper headset 0.2879, Fluid lapel 0.2195, whisper lapel 0.3262. The diarization scorer was rerun on both saved inputs and reproduced three clusters for four people, 2219/2600 correct headset word midpoints, 2200/2600 lapel, and warning coverage of 186/233 affected-speaker words plus 83 other-speaker words. The timing scorer rerun reproduced median start/end deviations of 0.07/0.07 seconds for Fluid and 0.46/0.51 for whisper. The six prescribed pbi18 gates all passed through the one wrapper with stamp 20261001_172200; log names are in the functional test record. These reruns supplement the earlier repeated wall-time and memory measurements, staged model hash checks, and process-level network-denial experiments already recorded in the report.

A fresh local-link check found zero broken links in 13 README/docs/Sprint 2 Markdown files. Narrative artifacts contain no Markdown tables; the progress board retains the required table. git diff --check passed. The benchmark is a completed measurement with explicit failures and limits. It does not validate FR-09 reliable participant identification, FR-10 alternate-input operator comparison, or natural minutes quality, and it does not select the production architecture. Those unresolved decisions are assigned to Sprint 3 PBI-012 and later work. No design approval remains pending for the measurement increment. PBI-018 is ready for a separate local completion commit.

## PBI-011 parent pre-commit reconciliation — 2026-10-01

The five child increments and PBI-018 have local completion commits 72fb8d4, 5c5a7bf, 1bae555, aafa38e, b70ef21, and 1e37f83. The root SRS, architecture, test profile, Sprint setup, accepted design and CLI amendment, implementation record, functional test record, README, benchmark report, and progress board were compared with their accepted scope and observed outcomes. The implementation and test records were corrected to distinguish completed gate and commit evidence from the remaining architecture and quality risks. The test record lists all 53 retained gate logs in its Artifacts section, including failed attempts and passing reruns.

The parent PBI-011 six-gate run used the single wrapper with label pbi11 on 2026-10-01. A1, A2, A3, B1, B2, and B3 all passed; their six timestamped logs end in 20261001_172551 and are linked from the functional test record. This is additional parent evidence beyond separate child gates. The root build, 18-case direct test suite, fixture regeneration, model runs, saved-record reload, and manual review seek are described in the implementation and test records. No natural-minutes content-quality pass is claimed.

The progress board now marks the parent and every Sprint 2 child tested and Sprint 2 implemented, consistent with the manager's post-quality-gate state. The benchmark provides measurements for Sprint 3 interpretation, while FR-09/FR-10 reliable participant identification and input comparison, natural minutes accuracy, bounded player replay, and model packaging remain explicit limits. No Plan, backlog, or Sprint 3 status was changed. No remote push was made. Local-link, copy/paste-block, narrative-format, and git diff --check results for final documentation review are recorded in the Sprint 2 documentation summary.

## Evidence-directory and FR-11 source audit — 2026-10-01

At the Product Owner's request, all 53 historical gate logs were moved from the Sprint 2 document root into `progress/sprint_2/tests/`. The single gate wrapper now creates that directory and writes its logs there. The test profile, test record, and documentation summary were updated to point at the new location. A fresh six-gate run with label evidence_move passed and wrote six additional logs there, bringing the retained log count to 59. The test record's Artifacts section links each log. The Product Owner also asked whether the current models meet FR-11. An official-source audit found that the exact Parakeet v2 and Whisper base.en variants measured in Sprint 2 are English only; candidate multilingual variants exist, but the present adapters expose no language control. The benchmark now states that distinction and cites the model documentation. This audit is a compatibility finding, not a Polish runtime claim. The Product Owner subsequently directed FR-11 into the active sprint; its design and implementation are a separate new increment.

## PBI-011.6 pre-commit reconciliation — 2026-10-01

The Product Owner approved the FR-11 design amendment and progress-board reset
on 2026-10-01. The root plan, SRS use case and FR-11, architecture, test
profile, Sprint setup and accepted design, implementation record, functional
test record, benchmark, README, documentation summary, and progress board
were reconciled to the same scope: explicit `en|pl|auto` transcription,
English-only model rejection, persisted request and model provenance, local
multilingual adapters, and paired referenced English/Polish comparison. The
FLEURS subset is natural read speech with both source gender classes in each
language, but has no verified speaker IDs and is not a Polish meeting. The
benchmark is decision-facing and includes per-language WER/CER, per-clip
results, model identity and license, resource observations, offline results,
and the `auto` mixed-language failure. The implementation record includes a
copyable Polish CLI and `cat`/`jq` human view. The original English AMI
evidence remains separate.

The first PBI-011.6 and PBI-018 language gate attempts were false positives:
unit and integration tests failed to compile, but the wrapper's final
timestamp command hid `tests/run.sh`'s nonzero exit. Log inspection caught
this before commit. The wrapper now returns the test status and records
PASS/FAIL; its `pbi6_retry` run correctly stopped at a failing integration
case caused by missing `transcriber` in two test settings files. After fixing
those files and the copyable example, the targeted integration case passed.
The corrected full PBI-011.6 run, stamp `20261001_211415`, passed all six
A1/A2/A3/B1/B2/B3 levels with actual `Finished: ... (PASS)` log endings.
The paired PBI-018 extension also has six passing corrected-wrapper logs,
stamp `20261001_211557`, ready for its separate completion audit and commit.
All failed attempts are retained and explained in the test record.

The root Swift package and Fluid helper build. The benchmark runner verified
all ten input hashes, persisted 20 explicit-language records, and scored
both models on identical clips in each language. Four single-language `auto`
runs passed; the mixed-language splice lost the English portion for both.
Polish offline runs succeeded with process networking denied. All 92 gate
logs now reside in the Sprint 2 `tests/` evidence directory and each has a
link in the functional test record. The source and scoring scripts pass
Python compilation; shell scripts pass `bash -n`; JSON manifests and results
parse. A fresh link and format check found zero broken local links in 16
README/Plan/board/docs/Sprint 2 Markdown files and zero tables in narrative
documents. The mandatory progress board retains its four-column table.
`git diff --check` passed. The board marks PBI-011.6 tested and keeps the
parent and Sprint under construction; PBI-018 remains under construction
pending its separate audit and local commit. No remote push is authorized.

## PBI-018 bilingual extension pre-commit reconciliation — 2026-10-01

PBI-011.6 was committed as `3717845` after its own audit. PBI-018's new
increment compares Parakeet v3 and multilingual Whisper base on the same
five English and five Polish FLEURS clips per language. The decision-facing
benchmark reports 11.49%/3.41% versus 18.39%/27.27% WER, Unicode CER,
per-sample outcomes, fresh-process wall times, model footprint, licensing,
input and model hashes, offline Polish inference, a Whisper Metal load
failure, and an exploratory mixed-language `auto` failure. The report
separates these short read-speech results from the earlier AMI English
meeting benchmark and preserves the limitations of the tiny sample and
missing verified speaker IDs. The SRS and architecture present model choice
as an open decision. The test profile, accepted Sprint 2 design, setup,
implementation, test record, README, documentation summary, and progress
board now agree that measurement is complete while Sprint 3 PBI-012 must
analyze it. The raw references, 20 paired runs, four `auto` runs, and mixed
records are saved in the Sprint 2 test evidence directory.

The corrected single gate wrapper ran A1/A2/A3/B1/B2/B3 for this PBI-018
increment with stamp `20261001_211557`; all six logs end with an actual
`Finished: ... (PASS)` and are linked in the test record. The earlier
`pbi18_languages` false-positive logs remain linked and explained. Before
this local completion commit, the source and scoring scripts compiled,
all results JSON parsed, 92 retained gate logs had 92 links, a fresh
16-document local-link and narrative-format check found zero issues, and
`git diff --check` passed. The board advances only PBI-018 to tested;
PBI-011 and Sprint 2 stay under construction until their corrected-wrapper
parent gates and separate reconciliation. No remote push is authorized.

## Reopened PBI-011 parent pre-commit reconciliation — 2026-10-02

The PBI-011.6 child and PBI-018 bilingual extension have separate completion
commits `3717845` and `caa51be`. The root SRS now includes the local
operator's language-selection use case and FR-11. The architecture keeps the
language request and model revision distinct, while the test profile names
the new contract checks and real-model comparison. Sprint setup, accepted
design and test specification, implementation record, functional test
record, README, benchmark, documentation summary, and progress board were
reviewed against those decisions and the executable CLI. The accepted
design's English/Polish candidate and `auto` paths have actual run evidence;
the report explicitly identifies the small read-speech subset, absent
verified speaker IDs, the Whisper Metal failure, and the missed English
portion in the exploratory mixed-language recording. These are Sprint 3
analysis inputs, not a claim of production quality.

The reopened parent used the corrected wrapper after both increment commits.
Its A1/A2/A3/B1/B2/B3 gates passed with stamp `20261001_213621`, and each
log has an explicit PASS finish. The new Polish copy-paste example was run
with the staged v3 model: `swift run meeting-summarizer transcribe` created
record `84C30D16-200F-4D48-9569-F709F30B359B`; the documented `cat`/`jq`
view printed `Requested: pl`, `Model: parakeet-tdt-0.6b-v3`, and Polish
transcript words beginning “Jakiekolwiek korekty lub żądania.” An
incompatible `.en` Whisper model and Parakeet v2 reject Polish in the
integration test without replacing the previous saved record. The 98
retained logs in `progress/sprint_2/tests/` are each linked by the test
record; no gate logs remain at the Sprint document root. The previous
false-positive attempt logs remain labeled as failures.

The parent and all children now meet their specified executable and gate
criteria. The board advances PBI-011 to tested and Sprint 2 to implemented;
PBI-018 is already tested. PLAN.md remains Progress pending the managed
Phase 5 Product Owner documentation approval and lifecycle update. The
documentation review is prepared but not marked complete. The final
pre-commit audit inspected 16 README/Plan/board/docs/Sprint 2 Markdown files
and found zero broken local links and zero narrative tables. Every PBI-011
and PBI-018 traceability symlink resolves, and no copyable Markdown block
contains an `exit` command. `bash -n` passed for the gate and test shell
scripts; both FLEURS Python scripts compiled; the 20-result JSON validation
passed; all six parent logs end in PASS; no gate log remains at the Sprint
document root; and `git diff --check` passed. The mandatory board is still
the four-column table. No remote push is authorized.
