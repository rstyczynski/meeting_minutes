# Sprint 2 — Documentation reconciliation gate

## Range correction and long-silence repair — pre-commit reconciliation, 4 October 2026

This local corrective increment follows `f79341e` and supports PBI-011.5/011.4 without closing either the broader minutes work or Sprint 2. The Product Owner accepted the GUI and selected-text designs, then directly requested same-speaker separation after tens of seconds of silence, an exposed parameter and an audio-position slider. The design record preserves the original failures and specifies the directed repair before its test cases/code.

The SRS FR-05 and NFR-04/05, candidate architecture, test profile, Sprint setup, accepted design/testing strategy, implementation, functional tests, README, manual, paired slide narrative, handover and progress board were checked against the code. FR-05/FR-06 were refined to reflect the Product Owner's directed long-silence boundary and slider; NFR-04/05 already cover traceability and non-destructive persistence. The setup clarifies the later explicitly requested public-meeting validation fixtures. No backlog/plan/status change is required for this usability repair. Core/store/CLI share correction validation; the GUI uses the same readable projection as multi-stage input. Raw text, source IDs, labels and history remain saved; obsolete derived results are invalidated. All eleven reading controls are now documented, including finite positive `longSilenceBoundarySeconds`, default 10 seconds. Short pauses remain joinable, and no default 15-second cap returns.

The parameter separates the demonstrated 148.40–181.68 s gap despite S1 on both sides. UT-21/IT-16 verify configurable boundaries, threshold equality, legacy decoding, preserved corrections and rejection without writes. UT-19/20 and IT-15 verify exact selections, Unicode, superseded overlap history, stale writes, contextual bounds and captured model-input consistency. `selection_compatibility_verified` (20261004_230115) and `long_silence_verified` (20261004_230950) each passed all six gates. The red/API, emoji, accidental post-repair fixture and long-silence red failures are retained and explained in the test record; failed attempts are never described as passes.

The full saved record was inspected and the documented configure-cleanup command executed on a disposable copy. The [receipt](tests/long_silence_review_20261004.json) shows five segments, both S1 paragraphs separated, 802/802 source parts conserved and both correction events retained. The [owner-session receipt](tests/selection_owner_session_20261004.json) observes the actual successful native crossing edit read-only. No test mutated the live store, and no new ASR/LLM inference or accuracy gain is claimed. The earlier controlled source-word GUI check remains historical. A separate QA launch was declined; native slider seeking/listening and range Restore/Cancel/restart are pending. The manual and handover expose those limits.

There is one canonical PPTX paired with a same-basename narrative. Nine superseded tracked PPTX files were removed as requested and remain recoverable in Git. Slides 9/18/19/21 now explain selected-phrase correction, the audio slider, the new threshold and resulting conclusions. All 21 slides were rendered; the four changed visible slides were inspected. Note 2 also updates the renamed narrative reference. The [validation receipt](tests/presentation_validation_selection_20261004.json) passed package/layout/font/reimport and native chart/workbook structure checks; unchanged chart/workbook bytes and other slides are checked in the [content receipt](tests/presentation_selection_review_20261004.json). Inherited warnings on slides 4/16 remain unchanged. Native PowerPoint execution is not claimed. Historical receipts retain their old scope/hashes.

Compiler excerpts in the retained red logs include trailing spaces. The scoped `.gitattributes` rule disables whitespace lint for raw Sprint test logs only, preserving their bytes; source and narrative diffs remain checked. Final pre-commit checks cover all local narrative links, shell syntax for the manual/demo, traceability links, the single-PPTX filename pairing, absence of narrative tables and git diff whitespace. The demo's optional single-source CLI correction now reports rejection and continues when a source is inside a range correction. Its full real-model journey is earlier rehearsal evidence, not a fresh complete live demo. Private slide build files and unrelated Finder metadata are excluded. The audit passes for committing the implemented repair and its evidence; native acceptance and broader sprint completion remain explicitly unresolved. No BACKLOG, PLAN or PROGRESS_BOARD status changed and no remote push is authorized.

## Historical checkpoint: per-source editor and one presentation — pre-commit audit, 4 October 2026

This corrective PBI-011.5 increment supports the PBI-011.4 operator workflow and follows completion marker `f79341e`. The Product Owner requested understandable correction instructions, one PPTX and a matching narrative, then approved the [GUI amendment](sprint_2_design.md#proposed-gui-transcript-corrections--2026-10-04): “Akceptuję — dodaj edytor do Meeting Review”, followed by “ok. accepted”. The accepted design and IT-14 specification preceded construction.

Meeting Review now offers Edit on each source part, source playback, corrected words, an explicit listening confirmation, Save correction, Restore original and Cancel. GUI and CLI call the same core/store operation. Saving reloads completed external edits, preserves raw words and correction history, clears obsolete minutes and topic results, and refreshes the reading view immediately. Validation or storage errors retain the editor input. The confirmation records the operator's assertion; it cannot establish that listening occurred. Simultaneous writers remain unsupported; external CLI changes require reopening the review app.

The SRS FR-05 and NFR-04/05, architecture, test profile, Sprint setup, accepted design/test specification and progress board were checked against the actual implementation. Store.swift, Record.swift, the CLI and Meeting Review implement the same non-destructive correction contract. IT-14 covers rejected writes, byte preservation, reload after a completed external name edit, correction, result invalidation, persistence and restoration. The existing UT-18 validator coverage is reused. Smoke gates build the native review product.

The red run at `20261004_221053` passed smoke but failed compilation because the new store operation did not exist; it also exposed missing test-fixture initializer arguments. The first implementation run at `20261004_221246` passed smoke but still failed those fixture arguments. They were corrected. All six `review_editor_verified` gates passed at `20261004_221532`. Failed attempts and passing replacements are individually linked under [Artifacts](sprint_2_tests.md#artifacts); no skipped gate is claimed as passing.

The [native GUI check](tests/review_editor_gui_20261004.json) used a QA bundle copied from the actual built executable and a controlled record. Edit, confirmation-dependent Save, immediate refresh, visible original ASR, Restore, Cancel and restart persistence were observed. Original segments remained unchanged and two correction entries persisted. The [screenshot](tests/review_editor_controlled_ui_20261004.png) shows this controlled editor. No audio was played; the checkbox was simulated. This verifies editing behavior, not real-audio accuracy or bounded playback. A separate [CLI documentation check](tests/operator_cli_documentation_check_20261004.json) executed correction, inspection and restoration on disposable controlled data with the same limited claim.

There is one delivered [presentation](sprint_2_increment_demo.pptx), paired with [sprint_2_increment_demo.md](sprint_2_increment_demo.md). The detailed live command order remains in [demo/README.md](demo/README.md), and the [manual](user_manual.md#correct-words-inside-meeting-review) gives both GUI and copyable CLI routes, expected saved results and recovery. Slide 9 now presents the actual editor and CLI alternative. The demo script offers GUI review before an optional CLI correction. Nine superseded tracked decks were removed from the checkout and remain recoverable in Git at `f79341e`; current links use the canonical file, while historical raw receipts retain their original hashes and metadata.

The [presentation validation](tests/presentation_validation_operator_steps_20261004.json) passed package, layout, font, chart/workbook and Artifact Tool reimport checks. All 21 slides were rendered and the final slide 9 visually reviewed. Twenty unchanged slides are pixel-identical; original chart/workbook bytes are preserved. The inherited slide 4/16 warnings are unchanged. [Content and consolidation checks](tests/presentation_operator_steps_review_20261004.json), local Markdown links, narrative format, demo/manual shell syntax and `git diff --check` form the final documentation gate. No native PowerPoint check or new ASR/LLM inference is claimed.

README, architecture, test profile, implementation, tests, handover, documentation summary, manual, narrative and demo describe the same tools, files and limitations. PBI traceability links resolve. No backlog, plan or board status changed: Sprint 2 and PBI-011/011.5 remain under construction. Real listening, reliable minutes, live Product Owner review and documentation approval remain pending. This is a completed corrective increment, not sprint closure. Private authoring files and unrelated Finder metadata are excluded; no remote push is part of this increment.

## Full metric name — pre-commit audit, 4 October 2026

The Product Owner requests the full name “Word Error Rate” instead of metric initials. This presentation/documentation correction follows completion marker `8fa8da0` and belongs to the PBI-011/PBI-018 handover. The separate [preferences file](../../RUPStrikesBack.patch/USER_PREFERENCES.md) records the durable terminology preference.

The current deck (`sprint_2_increment_demo_word_error_rate_20261004.pptx`, historical version in Git) expands the metric in the visible DOE limitation and AMI finding, and in the bilingual and AMI speaker notes. The canonical deck matches it. The earlier presentation remains as history. README, the benchmark, implementation, handover, documentation summary, functional test record, owner brief and presenter script use the full metric name and the current presentation link. Raw evidence and machine-readable metric fields retain their recorded form.

The SRS, architecture, test profile, sprint setup, accepted design/test specification and progress board were checked against the prior audit: this wording correction changes no requirement, product behavior, benchmark value, CLI command, scope or managed status. The same AMI reference comparison supports 19.48% and 28.79% Word Error Rate. Reliable minutes, manual playback and live Product Owner review remain pending. No new product inference or product-test pass is claimed.

Applicable checks are final package/layout/font/chart/workbook/reimport validation, rendered-slide comparison, full-name coverage, byte preservation outside the four changed slide/note parts, local links, narrative format, demo shell syntax and `git diff --check`. Results are retained in [the terminology review](tests/presentation_word_error_rate_review_20261004.json) and [presentation validation](tests/presentation_validation_word_error_rate_20261004.json). Native PowerPoint execution is not claimed.

## Presentation conclusion correction — pre-commit audit, 4 October 2026

The Product Owner accepts the parameter content but requests that the PPTX end with the substantial conclusions of the prototype. This is a presentation/documentation correction to the PBI-011/PBI-018 handover, following completion marker `87bbdcf`; no new product scope or managed status transition is introduced.

The current 21-slide deck (`sprint_2_increment_demo_conclusions_20261004_final.pptx`, historical version in Git) moves the unchanged parameter slides to positions 17–18. It ends with supported findings, remaining quality limits and next validation priorities on slides 19–21. The goals and architecture opening remains at the beginning. Slide 3's parameter pointer now names 17–18. The old ending's speaker/minutes limitations and pending Product Owner decision remain explicit in the new conclusion. The source pipeline deck is retained as history, and the canonical deck is the identical new validated file.

The owner brief, handover, presenter script, implementation pointer, architecture pointer, documentation summary and README now identify the same file and closing order. The script presents parameter details at operator review if useful and always ends with the conclusion. References in dated earlier audits remain historical. The [functional record](sprint_2_tests.md) distinguishes presentation checks from unchanged product gates.

SRS FR-03/04/05/09/10/11 and NFR-04/05/06, architecture, test profile, Sprint setup, accepted design/test specification, implementation and tests were compared with the conclusions. The cited evidence is the same-input AMI benchmark (19.48%/28.79% WER), qualitative Sejm PDF review, diarization's four-to-three cluster result, conserved 802-part reading correction, staged 30B citation audit (2/5 AMI and 2/4 Sejm summaries), child-process peak memory (16.01/17.34 GB), fresh demo failures and longer DOE minutes failure. Each conclusion slide's notes identify direct reports. The model-audit scores concern earlier saved profiles; the new grouping correction did not rerun or improve those LLM measurements. Quantitative scope and single-run limitations remain visible or in the corresponding notes.

The next-work directions are proposals for the existing Sprint 3 evidence assessment: operator source review, human topic/item references, semantic and voice boundary checks, and comparative long-input/resource experiments. They do not assign new backlog items. PLAN and the required progress-board table were checked against the prior audit and remain unchanged. The live demonstration, playback check, minutes acceptance, documentation approval and sprint-close decision remain pending.

The [presentation validation receipt](tests/presentation_validation_conclusions_20261004.json) records package, geometry, reference-font, native chart/workbook and Artifact Tool reimport checks for 21 slides. All final slides were rendered. The closing slides were individually reviewed and repaired for spacing. Fifteen earlier slides and both moved parameter slides remain pixel-identical; original chart/workbook package bytes remain unchanged. The [content and preservation review](tests/presentation_conclusions_review_20261004.json) checks that the final three slides are conclusions, the parameter pointer is correct and the canonical copy matches. Native PowerPoint execution is not claimed.

Applicable checks before this documentation increment's commit are deck/content/preservation validation, source-evidence review, local link and narrative-format checks, demo shell syntax and `git diff --check`. No product code or test contract changed, so the prior six passing `cleanup_verified` gates remain product evidence; no new product test pass is claimed. Temporary authoring files and unrelated Finder/PowerPoint metadata are excluded from the commit.

## Configurable reading pipeline correction — pre-commit audit, 4 October 2026

Scope: the Product Owner requires every reading segmentation parameter to be configurable, preservation of explicit speaker changes, an understandable pipeline in implementation documentation and a clear PPTX explanation of who performs diarization. This correction covers the PBI-011.5 reading path with PBI-011.4 review integration. It preserves the prior failed designs, original model measurements and managed-mode acceptance boundary.

**SRS checked:** FR-03/04/05 and NFR-04/05/06 were compared with the actual CLI and core. FR-05 now requires a saved, shared reading profile, source preservation, default speaker boundaries without duration/pause cuts, and invalidation of dependent minutes. Automatic person identification and semantic/audio-boundary reassessment remain unimplemented; this correction does not imply them.

**Architecture checked:** `Configuration.swift`, `Record.swift`, `Import.swift`, `Recognition.swift`, `TranscriptCleanupPolicy.swift`, `TranscriptCleanup.swift`, `MultiStageMinutes.swift`, the CLI, the review app and FluidAudio adapter were inspected. The architecture document and existing draw.io labels now distinguish audio ASR, separate FluidAudio diarization, Swift configurable joining, optional LLM minutes and quality gates. The diagram retains its geometry and now identifies the current 30B experiment while preserving 4B history. ASR parts receive diarization labels by greatest positive overlap. Full policy controls are in the [segmentation guide](transcript_segmentation.md).

**Test profile checked:** existing UT-14 and IT-13 remain in the sprint manifest. The final `cleanup_verified` wrapper run at `20261004_202120` passed all six new-scope and regression gates. UT-14 contrasts each control independently and retains the continuous S3, amount continuation and one-word S2 boundary cases. IT-13 uses a controlled adapter to capture the prepared model input and compare it with CLI inspection, without claiming real-model content quality. The [test record](sprint_2_tests.md) links final logs and identifies earlier failed attempts and historical checkpoints.

**Setup and accepted design/test specification checked:** the setup correction identifies the existing PBIs and preserves sprint scope. The design records the direct Product Owner instructions, all controls, defaults, validation and persistence/invalidation behavior before configuration construction. The earlier 15-second and pause-cut attempts remain visible. The tests described there correspond to the final code. Semantic and independent acoustic boundary validators remain open design work.

**Implementation and functional records checked:** the implementation begins with a six-step owner-facing pipeline, explains what runs on audio versus text, lists the complete ten-field JSON profile, and links runnable commands and interpretation. CLI inspection, review preparation and multi-stage minutes use the saved profile. Applying a changed profile clears stale derived results; applying the same profile skips a write. Invalid keys/values fail before save. The [Sejm receipt](tests/cleanup_configuration_20261004.json) tests profiles on a disposable copy, preserving all 802 source parts, names and active record bytes. It records four default turns, 802 source-part blocks, 32 duration-capped blocks and six gap-capped blocks. These are grouping counts, not word/speaker accuracy improvements. The operator command uses the current local record and was validated with only its store changed to a controlled copy. Optional time-limit fields omitted from encoded JSON mean disabled caps.

**Owner materials and README checked:** the manual, demo README, handover, Product Owner brief and documentation summary explain the same pipeline and policy. Current entry links point to the 20-slide pipeline deck (`sprint_2_increment_demo_pipeline_20261004_v2.pptx`, historical version in Git). Slide 3 shows processing order and technologies. Slide 4 separates ASR, diarizer and LLM. Slides 19–20 enumerate every control. Exact prompt examples remain on slide 4 and in implementation documentation. The canonical `sprint_2_increment_demo.pptx` is the identical validated copy. The former standalone naming deck remains historical evidence, and its slide 10 command remains unchanged in the new deck.

**Presentation checks:** the [receipt](tests/presentation_validation_pipeline_20261004.json) records package, geometry, reference-font, chart/workbook and Artifact Tool reimport passes for 20 slides. All slides were rendered. The four changed/new slides were inspected at full size and corrected for wrapping. The 16 unchanged slides render pixel-identically at the same scale; original chart and workbook package bytes remain identical. Slide 4's dense-paragraph warning was visually reviewed and fits; the inherited slide 16 chart text warnings are unchanged. No native PowerPoint execution pass is claimed.

**Progress board checked:** PLAN still assigns PBI-011 and PBI-018 to Sprint 2 Progress. The required board table remains unchanged: Sprint 2 and PBI-011/011.5 are under construction; sibling rows retain earlier evidence. This commit is a corrective increment, not sprint closure, Product Owner acceptance or a fresh GUI acceptance of PBI-011.4.

**Remaining review dependencies:** native AX and screenshot requests for the already running QA review app timed out. No new listening, bounded-playback or reopened-profile display pass is claimed. The previously prepared readable-card UI changes present in the shared workspace were integrated with policy selection; the build passes. The Product Owner's live playback check, minutes content acceptance and future semantic/acoustic boundary validators remain pending. These limitations are exposed in implementation, tests, manual and handover.

**Commit gate:** six tests passed; configuration JSON, draw.io XML, demo shell syntax, local Markdown links, narrative formatting and `git diff --check` are verified before staging. Source IDs and words are conserved. The low-level logs and receipts remain in `progress/sprint_2/tests/`. Temporary presentation build files, Finder metadata and the PowerPoint lock file are excluded. No managed artifact status, backlog or sprint-plan mutation is part of this commit.

## Copyable naming command correction — 2026-10-04

The Product Owner rejected the previous speaker-name slide because it used
uninitialized record/store variables and could not be executed on its own.
The current deck (`sprint_2_increment_demo_cli_ready_20261004.pptx`, historical version in Git) gives
the actual open Sejm record UUID, store and working directory on slide 10.
Its `bash -c` block asks for the verified name, then runs `recognize name`.
The presenter script contains the same block. README, handover, Product
Owner brief, implementation, functional test record and documentation
summary now point to this revision. The canonical deck is its exact copy;
the prior variable-based slide remains dated history.

The SRS FR-04/05, shared-store architecture, test profile, Sprint setup,
accepted CLI design/test specification, and progress board remain as
checked in the preceding audit: this changes the example, not the product
contract or status. The [focused test record](tests/speaker_naming_demo_20261004.md)
and [full-command receipt](tests/speaker_naming_copyable_command_20261004.json)
show the exact block executed on a disposable copy, with only the store
changed. The supplied name persisted, raw segments were unchanged, and
the active record remained byte-identical. The first attempt was blocked
by SwiftPM's nested sandbox before execution; the approved retry passed.
Human identity and reopened-player display remain live checks.

The slide was authored with Artifact Tool and merged into the original
package to preserve unrelated slides, native charts and their workbooks.
Only slide 10 and its notes changed. The
[finalization receipt](tests/presentation_validation_cli_ready_20261004.json)
records 18 slides and package, font, native chart data/workbook and reimport
passes. All slides were rendered; the changed slide was visually checked.
The canonical and dated files have SHA-256
`9ff706fe4b204c9eb979fb64f8685889f62820b1e604d77c2f503c9fe2ca2028`.
Applicable checks are the full-command test, shell syntax, local links,
narrative format, source-part comparison and `git diff --check`. No product
code or model prompts change in this presentation increment. Shared review
UI and user-manual edits remain outside this commit.

Final checks passed: full-command execution on the disposable record,
`bash -n` for the exact command block, 529 local links with zero missing,
no Markdown tables in revised narrative documents, and `git diff --check`.
Package comparison found only slide 10 and its notes changed. All 17
unchanged slides rendered pixel-identically to the source revision; the
changed slide was inspected at full size.

## Speaker naming in the Product Owner presentation — 2026-10-04

The Product Owner requested that the CLI naming explanation be included in
the presentation. The current 18-slide deck (`sprint_2_increment_demo_naming_20261004.pptx`, historical version in Git)
now shows `recognize name` on slide 10, its saved `speakerNames.S2` mapping,
the whole-cluster scope, and the need to close and reopen Meeting Review.
Stage 4 of the [demo script](demo/run.sh) prints the complete live command
and reopening command. The presenter script, Product Owner brief,
handover, implementation, functional test record, documentation summary
and README were reconciled with that operation. The canonical deck is an
identical copy of the new dated revision; the prior operator deck remains
historical evidence.

The SRS FR-04 and FR-05 were checked for chair-assigned names and use of
neutral labels. Architecture was checked for the shared record and player
reload; the test profile and Sprint setup for CLI persistence and operator
review; the accepted design and its test specification for `recognize
name`, existing-cluster validation and PBI-011.2/PBI-011.4. The board still
marks those children tested within the active, under-construction sprint.
No requirement, design, test contract or status changed. Shared review-app
and user-manual edits belong to a separate ongoing increment and are not
included in this presentation commit.

The [focused naming check](tests/speaker_naming_demo_20261004.md) executed
the actual CLI on a disposable copy of the real Sejm record. It saved the
supplied S2 label, left raw segments unchanged and preserved the active
record's empty name map. This checks persistence, not real identity or UI
playback. Human source listening, verified identity, display after reopening,
live handover and Product Owner acceptance remain pending.

All 18 final slides were rendered. The changed slide and both charts were
inspected at full size, followed by a whole-deck visual scan. The
[finalization receipt](tests/presentation_validation_naming_20261004.json)
records package, font, chart-data and reimport passes. Its slide 16 overlap
warnings were visually reviewed with no visible clipping. The SHA-256 is
`41175ba6518d0fc142220bdb22d381aa2d764d823fa6984d4068e75cf5eed7ae`.
Shell syntax, demo `--check`, local-link and narrative-format checks, and
`git diff --check` are the applicable pre-commit checks. Product code and
model prompts did not change in this increment, so ASR and minutes
benchmarks were not rerun.

Final pre-commit results: `bash -n progress/sprint_2/demo/run.sh` and
`bash progress/sprint_2/demo/run.sh --check` passed. The local-link scan
checked 517 targets with zero missing; revised narrative files contain no
Markdown tables. PPTX text comparison found only slide 10 changed, and the
canonical deck matched the validated dated revision byte for byte.
`git diff --check` passed.

## Product Owner single-command demonstration — 2026-10-04

The Product Owner requested a script they can execute which matches the
whole Product Owner presentation. The [one-command script](demo/run.sh),
[presenter sequence](demo/README.md), and current
[18-slide deck](sprint_2_increment_demo.pptx) now follow the same journey:
goal, architecture, real English and Polish transcription, weak audio,
operator review, neutral or verified speakers, staged 30B minutes, quality
gate, benchmark, and decision. The previous 14-slide file was preserved as
dated history (`sprint_2_increment_demo_initial_20261002.pptx`, historical version in Git) before the
validated 18-slide file became the canonical P9 path. The [deck validation
receipt](tests/presentation_validation_operator_20261004.json) confirms
18 slides, chart values, fonts, package integrity, layout and reimport;
rendered slide 16 was visually checked after its clipped imported labels
were rebuilt. Slides 8–10 show operator review and its unverified live
boundary rather than a fabricated speaker identity.

Earlier dated audit sections below call natural-meeting minutes a delivery
blocker because that was the review position when those increments were
tested. The Product Owner subsequently directed us to present that defect
as a prototype finding and next-work direction, without claiming correct
minutes. The current handover gate is an honest live demonstration of the
transcription, weak-audio, speaker/operator controls, model gate, and
measured limitations. That direction does not make the generated minutes
correct or close the open ASR, diarization, and human-review questions.

The root [SRS](../../docs/srs.md) was checked for FR-05, FR-09/10/11 and
NFR-06; the [architecture](../../docs/architecture.md) for separate
model interfaces and staged response validation; the
[test profile](../../docs/test-profile.md) for operational and manual
checks; [Sprint setup](sprint_2_setup.md) and accepted
[design](sprint_2_design.md) for PBI-011/PBI-018 and the operator boundary.
No requirement, design or status was changed by this demonstration work.
The [implementation](sprint_2_implementation.md), [functional tests](sprint_2_tests.md),
[README](../../README.md), [user manual](user_manual.md),
[documentation summary](sprint_2_documentation.md), [Product Owner brief](sprint_2_increment_demo.md),
and [handover](sprint_2_handover.md) were updated to point to the single
entry point and present fresh versus historical outcomes consistently.
The [progress board](../../PROGRESS_BOARD.md) still records the active
Sprint 2 and PBI-011/PBI-011.5 as under construction; this script does
not change those statuses.

The [rehearsal record](tests/po_demo_rehearsal_20261004.md) documents
`--check` passing and four complete real-model `--rehearsal` runs, including
the final script's 0 exit status. Fresh minutes were rejected in both
meetings, and the earlier source-audited successful 30B trial is labeled
as recorded comparison in the script and presenter text. No synthetic
meeting or `--fixture-reference` enters the demo. Operator playback,
audio-reviewed real correction, verified name assignment, Product Owner
questions, and handover decision remain pending until a person operates
the live script. The direct native UI replay could not be observed in
the developer's earlier rehearsal, so the document does not claim it.

The verification for this handover increment is the four full CLI
rehearsals, shell syntax and preflight, deck finalizer and slide render,
saved-record `jq` checks, local link and narrative-format scan, and
`git diff --check`; their final pre-commit results are recorded with this
increment. No product code or test implementation changed, so the earlier
PBI gate results remain separate. The managed handover decision and Phase
5 documentation approval are not inferred from the completed script.

Final pre-commit checks: `bash -n progress/sprint_2/demo/run.sh` and the
copyable `bash progress/sprint_2/demo/run.sh --check` passed. The last
real-model `--rehearsal` returned 0 and its per-step results are in the
rehearsal record; the minutes generator itself returned 2 for both fresh
meetings as shown there. A local-link scan checked 509 targets across
README and Sprint 2 narrative files with zero missing; the current
presenter, handover and rehearsal narrative has no Markdown tables.
`git diff --check` passed. The canonical deck and validated operator deck
have the same SHA-256
`06182177dea39ab4b607ea10c0332f880498fcb7d03e7bb71f6294cd342ec4bc`.

## Architecture-first presentation reconciliation — 2026-10-04

The Product Owner requested that the presentation open with Sprint goals and
architecture. The current 16-slide deck (`sprint_2_increment_demo_architecture_20261004.pptx`, historical version in Git)
therefore places the Sprint goal on slide 2, the shared local Swift system
and technologies on slide 3, and the ASR-versus-minutes model interfaces on
slide 4, before the real AMI and Sejm demonstration. Slide 4 uses exact
openings from the [current prompt ledger](sprint_2_implementation.md#current-staged-minutes-prompts-minutes-v41-multistage)
and explains that ASR receives audio and a language setting rather than a
free-text prompt. The final slide now treats the minutes defect as prototype
evidence while withholding acceptance of the generated minutes. The older
14-slide deck remains unchanged as historical evidence. README, handover,
Product Owner brief, and documentation review link the current deck.

The new deck has 16 slides and retains two editable native benchmark charts.
The imported historical charts lacked source-workbook relationships, so
they were rebuilt from the complete literal values in the [benchmark](ami_asr_benchmark.md):
AMI WER 19.48% and 28.79%; English read-speech WER 11.49% and 18.39%;
Polish read-speech WER 3.41% and 27.27%. The finalizer created new chart
workbook snapshots and verified package structure, chart data, font policy,
layout, and reimport. The [validation receipt](tests/presentation_validation_20261004.json)
records the SHA-256 and checks. All 16 final slides were rendered; the new
opening, changed quality-gate and conclusion slides, and both charts were
visually inspected. This validates the presentation artifact, not a live
Product Owner demonstration or the generated minutes.

The SRS, architecture, test profile, Sprint 2 setup, accepted design,
implementation prompt ledger, functional test record, benchmark, README,
and progress board were checked for this presentation change. No product
behavior, requirement, copyable product command, test outcome, or sprint
status changed. The live demonstration and explicit managed handover
decision remain pending. Local links, document wording, and
`git diff --check` are the applicable pre-commit checks.

The pre-commit scan checked 197 local links in the five updated narrative
files and found no missing targets. PPTX inspection confirmed the intended
slide order, 16 slides, two native charts, and the revised conclusion.
`git diff --check` passed. No Swift or model test was rerun because this
increment changes presentation and documentation only.

## Prototype-conclusion reconciliation — 2026-10-04

The Product Owner directed that the minutes-content failure be documented as
an explicit Sprint 2 prototype result and direction for later validation,
without accepting the generated minutes or declaring the sprint complete.
The implementation conclusion, handover, Product Owner presentation brief,
documentation review, and README now state that distinction consistently.
The older one-call failure and the staged trial remain visible; the
[controlled trial](tests/multistage_minutes_trial_20261004.md) supports the
217/217 and 801/801 raw-segment preservation, 21/21 and 32/32 utterance
coverage, 2/5 and 2/4 source-supported topic summaries, and the specific
topic errors cited in the revised narrative.

For this documentation-only reconciliation, the SRS, candidate
architecture, test profile, Sprint 2 setup, accepted design, functional test
record, benchmark, and progress board were checked against the recorded
decision and measured behavior. None requires a requirement, architecture,
test-command, or status change to state the prototype conclusion. The board
still marks Sprint 2 and PBI-011/PBI-011.5 under construction. The live
Product Owner demonstration, minutes quality validation, Phase 5 approval,
and sprint closure remain pending. No new code, model inference, or copyable
command was added by this documentation change; the checks for this edit
are local links, factual source references, narrative format, and
`git diff --check`.

The six changed narrative files contain no Markdown table rows. A local-link
scan checked 245 local targets across them and found none missing. The AMI
and Sejm metrics files confirm 217 and 801 raw segments, respectively; the
controlled trial supplies the utterance coverage and manual source-audit
denominators. `git diff --check` passed. The historical blocker wording in
the handover is explicitly dated and followed by the later Product Owner
direction. No executable example changed, so the code and six test gates
were not rerun for this documentation-only reconciliation.

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

## Phase 5 documentation quality correction — 2026-10-02

The Product Owner tried a copyable command in the implementation record and
correctly received `Media file does not exist`: the documented media and
settings paths were literal placeholders. The canonical RUP Documentor
procedure requires extraction and execution of snippets, rejection of
placeholders, verification of expected output and prerequisites, and a
consistency check before documentation approval. The previous Phase 5
review covered links and formatting but failed this executable-example
criterion. The invalid block was removed rather than relabeled as working.

The implementation record now gives a Product Owner validation path. Its
end-to-end synthetic CLI flow uses checked-in WAV and reference files and
was rerun: record `EC9EB600-9DDC-4CD9-9009-A02C9EDC2387` had five turns,
speaker_2 named Ada, the first turn moved to speaker_2, and four source-linked
review items. The real Polish example now has one-time staging commands for
the FLEURS clip and v3 model, explicit prerequisites, an executed CLI command,
and the verified `cat`/`jq` result. The failure example uses a deliberately
missing file and states the expected status. The README and documentation
review point to these instructions and explain their validation purpose.
All eight executable shell blocks in README, implementation, and functional
test records were checked for placeholder paths, `exit` commands, and shell
syntax; none failed. The missing-media example was rerun and returned status
2 with the expected message. A fresh 16-document scan found zero broken
local links and zero narrative tables. Both PBI traceability directories
have no broken symlinks; the 98 retained gate logs have 98 document links;
and `git diff --check` passed. The documentation correction has no product
code change, so prior passing product gates remain valid. Managed Phase 5
approval is still pending before this correction is committed as the
documentation completion marker.

## Phase 5 model-versus-fixture correction — 2026-10-02

The Product Owner challenged the apparent end-to-end model claim in the
`--fixture-reference` walkthrough. Inspection confirmed that this option
injects prewritten transcript, speaker, and minutes data, so the walkthrough
checks CLI dispatch, chair correction, source links, and persistence only.
The implementation record now directs Product Owner review first to the
real-model benchmark, labels the short Polish Parakeet run as actual ASR
inference, and isolates the fixture walkthrough under a synthetic CLI
contract heading. The README and documentation review state the same
boundary. This correction changes documentation only; it does not add model
test evidence. The AMI and FLEURS results and their quality failures remain
the model-validation evidence. Managed Phase 5 approval remains pending.

## Phase 5 test-only option placement — 2026-10-02

The Product Owner directed that the reference-injection command be described
in the test record and excluded from implementation instructions. The complete
synthetic CLI sequence, human-readable saved-record view, and expected
contract outcome were moved to `sprint_2_tests.md`. The implementation record
now contains the real Polish model run, actual settings and media staging,
expected transcript, and a missing-media error example without the test-only
option. The README and documentation review were reconciled to those paths.
No product code or benchmark result changed. Managed Phase 5 approval remains
pending.

The revised missing-media command was executed without the test-only option;
it printed `Media file does not exist` and exited 2. `git diff --check`
passed after the document move.

## Phase 5 Product Owner walkthrough gate — 2026-10-02

The Product Owner required the implementation record to demonstrate four
tasks: transcribe English and Polish, inspect low-quality recording elements,
assign names, and generate a summary. The Documentor's existing
copy-paste/expected-output responsibility applies to those actual product
tasks. The implementation record now gives one same-session walkthrough
using staged real models and real AMI/FLEURS audio. It explicitly states
that Polish input is a single sentence, the AMI full meeting is needed to
show warnings, anonymous S3 merges two annotated people, and the local MLX
minutes fail content quality. It identifies local-model packaging as an
unresolved fresh-Mac dependency. The README and documentation review now
point to the walkthrough; the functional test record holds the observed
record IDs and keeps the synthetic contract path separate.

The English AMI v2 CLI created record
`F4A47777-5288-4498-95D5-0A067D7DBA2E` with 2,576 segments. Fluid
recognition saved S1/S2/S3 labels and 16 S3 warning ranges. The first
begins at 19.32 seconds. The manual name command saved `S2 = Ada (demo
label)`. The Polish v3 CLI created record
`685ABDCF-BF44-42BA-9A9F-DD2F8734F6FA` with 15 Polish segments. A
120-second AMI record `4CDA78E1-3E3A-4380-875B-CC976A53CB72` passed
through transcribe, recognize, name, and real MLX summarize; its six review
items contain unsupported content and repeat the demo label. The documented
human-readable `jq` expressions were run on these saved records. The
missing-media command without a test hook exited 2 as documented. The
walkthrough commands are executed evidence for the Product Owner, not a
claim that its minutes or low-quality identification meet production
acceptance. Managed documentation approval remains pending.

After the walkthrough rewrite, 16 README/Plan/board/docs/Sprint 2 Markdown
files had zero broken local links and zero narrative tables. Twelve Bash
blocks in the implementation and functional test records passed `bash -n`;
none used a placeholder path or an `exit` command. The implementation record
contains no `--fixture-reference` option. The three saved real-model records
were reloaded: English has 2,576 segments, 16 warnings, and the persisted
demo name; Polish has 15 segments with requested language `pl`; the short
AMI record has six items with `minutesSource: local-model`. The documented
human-readable `jq` expressions ran against these records. `git diff
--check` passed. Product code was not changed, so these are documentation
and executable-example checks, not a new six-gate product increment.

Preflight and settings blocks also ran exactly as written. A single nested
Bash replay of all walkthrough blocks stopped before transcription when
SwiftPM could not apply its own sandbox under Codex's filesystem sandbox.
The [failed replay log](tests/product_owner_walkthrough_nested_sandbox_failure_20261002.log)
is retained and linked from the functional test record. Each direct model
command had already run successfully and saved the records described above;
the integrated nested replay is not presented as a pass.

## P9 increment handover preparation — 2026-10-02

The Product Owner explicitly requested execution of the newly added local
P9 handover procedure. It is compatible with the canonical Phase 5
Documentor: the developer presents the increment before the managed
documentation-approval decision, without changing PBI acceptance, board
states, or PLAN status. The initial root `user_manual.md` explained prerequisites,
the four supported product tasks, exact commands and expected results,
common recovery, and current limits. The six-slide
`sprint_2_increment_demo_initial_20261002.pptx` maps the live path to PBI-011 and the measured
comparisons to PBI-018, discloses the speaker, minutes, and language-switch
failures, and asks for a Product Owner handover decision. The separate
`sprint_2_handover.md` records claims, checks, limits, and pending feedback.
README and the Sprint 2 documentation review link to the package. Both
assigned backlog directories link to the handover and deck.

All six slides were rendered and visually inspected at full size. The first
draft's chart legends were too small; the revised deck uses large model
labels and keeps editable native charts on slides 3 and 4. Its finalization
passed package integrity, chart-data packaging, font, and layout checks.
The initial copied sprint deck had SHA-256
`256cec84f396eab03b34f81fea7c003ddb729ae040c36e9f263a9236f235c581`.
The deck was inspected through rendering, not opened in PowerPoint. Eighteen
README/Plan/board/docs/manual/Sprint 2 Markdown files had no broken local
links and no narrative Markdown tables. The manual's four Bash blocks and
the implementation and test Bash blocks passed `bash -n` with no placeholder
paths or `exit` commands. The real-model run evidence and failing nested
replay are described in the functional test record. All traceability
symlinks resolve; `git diff --check` passed. The handover is prepared for
the Product Owner's explicit review, so Phase 5 completion, commit, and
sprint closure remain pending.

The final handover scan included the new manual and handover record: 18
Markdown files had no broken local links or narrative tables, 16 Bash blocks
in the manual, implementation, and test record passed `bash -n`, all 99
retained `.log` files in the Sprint 2 test directory are linked from the
functional test record, and every PBI-011/PBI-018 traceability symlink
resolves. The manual's five `jq` views returned the documented English and
Polish segment counts, warnings, demonstration name, and minutes-source
marker from real saved records. The copied slide deck's SHA-256 matches the
validated final deck, and `git diff --check` passed again. Product Owner
handover acceptance has not been inferred from these checks.

## P9 live demonstration and location correction — 2026-10-02

The Product Owner corrected the manual location. P9 now makes
`progress/sprint_N/user_manual.md` the handover source and allows a reviewed
copy in `docs/` later. Sprint 2's manual moved into its process directory;
README, the documentation review, and handover links were updated. The deck's
Live demo slide now states the starting state, four actions, and visible
results. The revised six-slide deck passed package, chart, font, and layout
validation, was rendered, and slide 2 was visually inspected. Its SHA-256 is
`598bee9d8d257ac1f7a26ffb347f483921f8d3738675609065ffb01ed54efbd9`.

The developer then performed the four-step CLI scenario in a fresh local
store with real models and saved the observed record IDs and outcomes in
[the handover record](sprint_2_handover.md). The live result repeated the
known limitations: three labels for four AMI people, 16 weak-audio warning
ranges, and six draft minutes items containing unsupported content. No
reference-injected test data was used. The manual's new fresh-store command
ran successfully. A final scan found zero broken local links or narrative
tables across 18 Markdown files; 17 Bash blocks in the manual, implementation,
and test record passed `bash -n`; all 99 retained logs are cited by the test
record; 18 traceability symlinks resolve; and `git diff --check` passed.
The Product Owner decision, Phase 5 documentation approval, commit, and
sprint closure remain pending under P9.

## Sejm meeting correction and minutes defect — 2026-10-02

The Product Owner rejected the single-speaker FLEURS clips as meeting demo
inputs and approved a Sejm committee sitting. The handover now uses a real
ten-minute Polish multi-person excerpt with an official recording entry and
written sitting record. The [fixture record](polish_sejm_meeting_fixture.md)
gives the source URL, local media hash, staging command, and reference limits.
The [test capture](tests/polish_sejm_meeting_run_20261002.json) records 802
timed segments, three speaker IDs, the chair name basis, the initial minutes
error, and the repaired rerun. No FLEURS sentence is described as a meeting
or used in the product walkthrough.

The Product Owner identified the minutes error as a blocking product defect
and said the increment is not ready for delivery. Source inspection found
that the model cited speaker label `S1` instead of a source segment ID; the
strict validator correctly rejected the item. The adapter now distinguishes
`SOURCE_ID` from `SPEAKER` and retries once for an invalid citation. The
core now drops an action owner unless the cited segments contain that
speaker. The focused regression test passed, and all six Sprint gates passed
in the [2026-10-02 gate logs](sprint_2_tests.md#polish-multi-person-meeting-correction--2026-10-02).
The real Sejm rerun saved four draft items. Content inspection against the
cited transcript found a valid positive-opinion decision but also a false
action and invented open question. The summary has no source citation.
These content defects remain a delivery blocker; the repaired structural
path is not represented as a successful minutes-quality result.

The [manual](user_manual.md), [implementation record](sprint_2_implementation.md#product-owner-walkthrough--real-local-models),
[test record](sprint_2_tests.md), [handover record](sprint_2_handover.md),
[documentation review](sprint_2_documentation.md), README, and 13-slide
deck (`sprint_2_increment_demo_initial_20261002.pptx`, historical version in Git) now reflect the real Sejm journey and
remaining blocker. At that point, the copied deck SHA-256 was
`000ef7f4bda0e89b499b0e73a972ade07acbc55c07d27f6da0604d9db3d1d39f`;
package, layout, native-chart, font, and import validation passed. All 13
slides were rendered; the changed Polish minutes slide was visually
inspected. A fresh audit of 14 README/Sprint 2 Markdown files found zero
broken local links, zero narrative tables, and no Bash syntax errors in 24
copyable Bash blocks. The fixture restaging block ran and returned the
documented duration, size, and SHA-256. `git diff --check` and the compact
JSON capture parse passed. An additional summary-citation prompt experiment
was discarded after it switched languages and added unsupported budget
detail on the same record. The final `minutes-v2` code passed all six gates
again, as linked from the test record. Product Owner live review, handover
acceptance, Phase 5 completion, and commit remain pending.

## Longer English meeting and second minutes model — 2026-10-02

The Product Owner requested a longer English official meeting. The
[DOE fixture](doe_itiac_day2_fixture.md) and [run capture](tests/doe_itiac_day2_run_20261002.json)
document a 30-minute, multi-person excerpt with an official speaker-labeled
transcript. The real CLI saved 4,216 timed English segments and eight
anonymous speaker IDs. Both local minutes models exited on structured
output for that full excerpt; neither saved review items. A staged 7B
alternative also failed source-content review on the same Sejm transcript
used for the 4B model. The [benchmark](ami_asr_benchmark.md#polish-meeting-minutes-quality-check)
now gives the same-input comparison and explicitly withholds a default
minutes-model choice. The manual, implementation record, test record,
handover, documentation review, and README link the new source and state
the delivery blocker. The updated deck includes the DOE failure and has
SHA-256 `184d289cc25b538eaba6c05daf172ae772864defa3bfc4df8beb78789f693f84`.
It passed package, layout, font, native-chart, and import validation;
all 13 slides rendered and the changed failure slide was visually checked.

The canonical bug policy requires sprint defects under their affected item.
[Sprint 2 bugs](sprint_2_bugs.md) now records the repaired citation error
separately from the open Sejm content defect and DOE structured-output
failure. A fresh README/Sprint 2 audit covered 16 Markdown files and 26
copyable Bash blocks, with zero broken local links, zero narrative tables,
and zero Bash syntax failures. `git diff --check` passed. This is a
documentation check, not a minutes-quality pass or handover approval.

## Sejm PDF transcription comparison — 2026-10-02

The Product Owner pointed out that the official Sejm PDF can test more than
meeting provenance. The [passage-level review](tests/polish_sejm_pdf_transcription_review_20261002.md)
now compares the saved Polish transcript with PDF pages 4–5 over the formal
opening through the beginning of the next agenda item. It documents
recognizable turns, monetary amounts, and the positive-opinion decision,
alongside word, name, acronym, and numeric-unit errors. The edited PDF is
not a time-aligned verbatim reference, so no whole-excerpt WER was added.
The fixture, benchmark, test record, implementation, handover, and
documentation review were reconciled with this narrower finding. The
README/Sprint 2 Markdown audit again found zero broken links, zero
narrative tables, and 26 syntactically valid Bash blocks; `git diff --check`
passed. Minutes quality remains blocked independently of this ASR review.

## Product Owner presentation set and final consistency check — 2026-10-02

The [presentation brief](sprint_2_increment_demo.md),
13-slide deck (`sprint_2_increment_demo_initial_20261002.pptx`, historical version in Git), [manual](user_manual.md),
and [handover record](sprint_2_handover.md) now form one review set. The deck
shows real AMI and Sejm inputs, actual saved transcript and warning output,
the deliberately invented AMI alias, neutral Sejm speakers, the supported
decision, unsupported draft minutes items, and the longer DOE minutes
failure. Its charts retain the benchmark's cited scope. Speaker names are
not inferred from a whole cluster merely because the official PDF names a
chair on one turn. The latest fresh [AMI](tests/43CE873A-603C-473F-9B23-A785A0689456.json),
[Sejm](tests/5DC83D71-D1B0-4568-A66D-70F3B9A71D46.json), and
[short AMI](tests/4395B92A-60B8-4B8C-9A20-3AE37642FE92.json) records
support the shown segment counts, warning, name state, and draft-item
examples. The test and handover reports distinguish those fresh results
from earlier exploratory records.

The final deck SHA-256 is
`c6ffc49272a149380505e383741147b345db362684e84affe5f46804a7a28cd7`.
Presentation package, layout, font, chart, and import checks passed; all
13 slides rendered and were reviewed for readability. The PPTX archive
passed `unzip -t`. The Markdown audit covered 17 README/Sprint 2 files and
26 copyable Bash blocks: zero broken local links, zero narrative tables,
and zero Bash syntax errors. The three fresh JSON captures passed `jq empty`,
and `git diff --check` passed. The commands retained in the manual and
implementation record use the `swift run` entry point that succeeded in
the fresh rehearsal. Direct debug-binary summarization aborted with an
unexplained adapter exception; that path is not counted as passed.

This completes preparation and document consistency checking for the
presentation set. It does not complete the P9 live demonstration or change
the Product Owner's minutes-quality blocker. Product Owner questions,
handover decision, Phase 5 approval, increment commit, and sprint closure
remain pending.

The subsequent blocker investigation retained the 4B DOE adapter's
[truncated raw response](tests/doe_minutes_raw_adapter_response_20261002.json)
and a [diagnosis](tests/doe_minutes_failure_diagnosis_20261002.md). It also
reproduced the direct-binary exception and the successful same-record
`swift run --skip-build` route. At the time of that investigation the
[recovery design](sprint_2_design.md#approved-minutes-quality-recovery-amendment--2026-10-02)
was a proposal. The Product Owner subsequently approved it, and the
implementation and presentation were updated as recorded below. The
BUG-3 root cause is narrowed only for the 4B attempt; the 7B raw output
was not retained.

## Approved response gate and presentation reconciliation — 2026-10-02

The Product Owner approved the evidence-first repair and asked for
technical checks of non-deterministic model responses, bounded repair
prompts, an NFR, implementation guidance, tests, and a Product Owner demo.
NFR-06 is in the SRS; the architecture and approved design describe the
gate; the implementation record includes the exact active and historical
prompts. Controlled validator, core, and integration tests cover malformed
JSON, schema and citation faults, bounded retry, transcript preservation,
and the ten-minute limit. The single six-gate wrapper passed A1–A3 and
B1–B3 with stamp `20261002_155412`; the [test
record](sprint_2_tests.md#evidence-first-minutes-and-response-gate--2026-10-02)
links each retained log.

The Product Owner manual, presentation brief, documentation summary, and
handover now distinguish old `minutes-v2` saved drafts from the current
evidence-first gate. The 14-slide deck (`sprint_2_increment_demo_initial_20261002.pptx`, historical version in Git)
contains a gate slide that states the real Sejm draft still fails. Package
and layout validation found 14 slides and zero layout findings; all slides
were rendered and the new slide was visually inspected. The Sprint and both
PBI deck copies have identical SHA-256
`6f6c77616f5ec6b57d3df5f044878214af750611eb12af9877dd29efcb6a47c2`.
Twenty README/docs/Sprint Markdown files had zero missing relative link
targets, narrative documents had zero Markdown tables, and
`git diff --check` passed. The active gate has not yet yielded a useful
real-meeting minutes draft; Product Owner acceptance and Sprint closure
remain blocked.

## 30B model staging evidence — 2026-10-03

The Product Owner asked to continue the larger local model download.
The temporary partial transfer from the previous day was absent, so the
download restarted in the persistent Git-ignored `.models/` directory.
The [download record](tests/qwen3_30b_download_20261003.md) identifies
the pinned Hugging Face revision, complete 16-file manifest, exact
shard sizes, matching SHA-256 hashes, and connection-reset recovery.
The [benchmark](ami_asr_benchmark.md#evidence-first-gate-and-larger-local-model-candidate),
[implementation record](sprint_2_implementation.md), and [test
record](sprint_2_tests.md#evidence-first-minutes-and-response-gate--2026-10-02)
were synchronized at staging. The model has since run in the controlled
same-input trial below. The product default and Sprint 2 acceptance
status are unchanged.

## 30B trial documentation reconciliation — 2026-10-03

The [trial report](tests/qwen3_30b_minutes_trial_20261003.md) includes
the clean-input identity check, raw response attempts, saved outputs,
source review, timings, memory observations, and failure interpretation.
The benchmark now gives the Product Owner the model comparison and
decision without requiring reconstruction from logs. The implementation
record identifies the opt-in raw-response capture and Metal resource
packaging step; the test record distinguishes technical acceptance of
AMI's short quotation from the failed Sejm JSON and minutes quality.
The handover and presentation brief retain the delivery blocker. The
normal manual still demonstrates the 4B product setting because the 30B
candidate was not promoted. A fresh `swift test` run passed four focused
adapter tests, and the [six Sprint gates](sprint_2_tests.md#evidence-first-minutes-and-response-gate--2026-10-02)
passed with stamp `20261003_143640`. All seven raw attempt and saved
record JSON files passed `jq empty`. A link scan of the nine edited
decision and evidence Markdown files checked 355 local links with zero
missing targets; the same files have no narrative Markdown tables, and
`git diff --check` passed. This audit checks document
consistency and traceability, not model quality or Phase 5 acceptance.

## Timed transcription boundary clarification — 2026-10-03

The Product Owner approved describing transcription as a simple ordered
sequence of timed text, with Swift creating the stored meeting-record JSON.
This documents current behavior rather than changing the executable
contract. Inspection of the FluidAudio helper showed that it converts
available token timings to segments and falls back to one timed text
segment when timings are absent. Inspection of the whisper.cpp adapter
showed that it reads the engine's JSON output mode as temporary transport
and converts offsets to `TranscriptSegment` values. MeetingCore then
validates and persists the record. Neither ASR path receives the MLX
minutes text prompt. The CLI currently returns a record UUID; the
documented `jq` views expose the timed segments, with no claim of live
caption streaming.

The root [SRS](../../docs/srs.md) FR-01–03 already require a local,
timestamped transcript, so no requirement text changed. The
[architecture](../../docs/architecture.md), accepted
[Sprint design](sprint_2_design.md), and
[implementation record](sprint_2_implementation.md) now state the data
boundary and distinguish engine transport JSON from the persistent
MeetingCore record. The [test record](sprint_2_tests.md) already links
the CLI transcript and storage checks; no behavior or test was changed.
The [Sprint setup](sprint_2_setup.md) and
[progress board](../../PROGRESS_BOARD.md) retain their accepted scope and
`under_construction` status. The [README](../../README.md) now explicitly
keeps the minutes-quality delivery blocker visible.

The accepted [test profile](../../docs/test-profile.md) previously barred
all real meeting transcripts from Git, while the Product Owner had
approved public AMI, Sejm, and DOE fixtures and required inspectable
Sprint evidence. It now distinguishes private meeting data, which remains
barred, from approved public evidence with recorded source and rights;
large media and weights remain outside Git. The [benchmark](ami_asr_benchmark.md)
and [30B trial](tests/qwen3_30b_minutes_trial_20261003.md) now state that
the long quote-only minutes prompt may confound the model comparison.
Simplifying the minutes prompt has not been approved or implemented.
No new product test is claimed for this documentation-only clarification;
the prior six-gate run remains the last executable verification.
An actual saved AMI record was read with `jq`; its first three timed
segments start at 4.72, 4.88, and 5.28 seconds, confirming the
documented offset/text shape. A fresh scan of the eight edited narrative
files checked 168 local links with zero missing targets and found no
Markdown tables. `git diff --check` passed. The unresolved dependency is
the separate minutes prompt redesign and its managed-mode approval; this
clarification does not advance PBI-011.5 or the Sprint status.

## Draw.io architecture overview — 2026-10-03

The Product Owner requested an editable high-level architecture diagram with
the technology behind each element. The [architecture](../../docs/architecture.md)
now embeds a rendered preview and links the editable
[draw.io source](../../docs/architecture_overview.drawio). The diagram was
reconciled with the Swift package, CLI, review player, local store, FluidAudio
and whisper.cpp transcription adapters, speaker diarization, and MLX minutes
adapter. It shows transcription as timed text that Swift stores in a meeting
record. The optional recognition and minutes paths remain distinct.

NVIDIA's model cards distinguish the English-only Parakeet v2 from the
multilingual v3 used for the Polish Sejm transcription. NVIDIA also lists a
Polish-capable 1.1B multilingual RNNT model, but it is neither integrated nor
benchmarked here; the architecture text marks it as a candidate rather than
an implemented component. The diagram and text retain the real-meeting
minutes-quality blocker: the 30B trial improved one narrow citation result,
but did not produce dependable minutes on the AMI and Sejm examples.

The draw.io application exported the native source to a 1744×1018 PNG, and
the preview was visually inspected. XML parsing found one diagram page,
14 component cells, and nine connections. All local links in the edited
architecture document resolved, and `git diff --check` passed. This was a
documentation-only increment; no product-code test or sprint-status change
is claimed.

## Readable meeting transcripts — 2026-10-03

The Product Owner asked to see the actual transcriptions in files. The
[transcript index](tests/transcripts/README.md) links complete rendered
text for the full English AMI meeting, its 120-second evaluation excerpt,
and the ten-minute Polish Sejm excerpt. Each view is generated from a
committed saved MeetingCore JSON record, includes timed lines and anonymous
speaker labels, and links the segment-level source. The implementation
record now points directly to these files so the Product Owner can inspect
ASR output without assembling it from JSON or logs. The index states that
the DOE saved record is unavailable and separates the short FLEURS and
mixed-language probes from real meetings.

The exporter does not infer identities or correct ASR words. Verification
compared every rendered text token with the corresponding saved segment
sequence, checked local links and `git diff --check`, and confirmed the
three source record counts: 2,582, 217, and 801 segments. This is an
evidence-presentation change; it does not improve transcription accuracy
or clear the minutes delivery blocker.

## Accepted multi-stage minutes repair design — 2026-10-03

The Product Owner asked to retain the earlier evidence-first design, show
why it failed on real meetings, and add a multi-stage repair with mandatory
utterance-to-topic coverage. The [Sprint design](sprint_2_design.md#approved-multi-stage-minutes-repair-design--2026-10-03)
now keeps the approved one-call design intact, cites the AMI and Sejm 30B
trial and earlier benchmark, and specifies transcription cleanup, topic
discovery, complete utterance assignment, per-topic summaries, decisions,
commitments, tasks, questions, cross-topic checks, and human review. The
Product Owner identified Sejm speaker splits around isolated `Na` and `i`
tokens and a longer S1/`Unassigned` continuation. The separate transcription
correction-method section now
requires each isolated-token candidate to be checked against both
neighbors, with a recorded merge, independent-turn, artifact, or unresolved
result. A direct scan of the saved Sejm segments found 12 one-word
`Unassigned` tokens between the same labeled speaker with at most 1.5
seconds on each side; this is a candidate count, not confirmed error count.
The design accounts for every saved text-bearing segment in one cleaned
utterance or an explicitly reviewed artifact record. Every substantive
utterance needs at least one topic; unresolved cleanup or topic assignment
blocks a complete draft. The section names unit, integration, and
real-model evaluation checks, but no test skeleton or code has been
changed. The Product Owner accepted this revised design on 2026-10-03;
that decision does not count as a product-quality pass.

Reconciliation updated the [FR-05 use case and requirement](../../docs/srs.md)
with the accepted correction, traceability, and topic-coverage outcomes.
The durable [architecture](../../docs/architecture.md) now distinguishes the
accepted next design from the implemented one-call prototype. Reconciliation
also checked NFR-06, the [test profile](../../docs/test-profile.md),
[Sprint setup](sprint_2_setup.md), [implementation](sprint_2_implementation.md),
[functional test evidence](sprint_2_tests.md), [README](../../README.md),
and [progress board](../../PROGRESS_BOARD.md). The latter documents still
describe the executed prototype; none is rewritten as if the new candidate
already works. Sprint 2 and PBI-011.5 remain `under_construction`; the minutes
delivery blocker remains. Test skeletons, product code, and real-meeting
evaluation are the remaining work before an increment-completion commit.
This documentation-only
change requires link, formatting, and `git diff --check` verification, not
a new product test run. The final static pass resolved 83 local links across
the edited SRS, architecture, design, and audit with zero missing targets.
The new narrative section has no Markdown table, and `git diff --check`
passed.

## Executed staged-minutes experiment and Product Owner conclusions — 2026-10-04

This audit reconciles the approved PBI-011.5 repair with executable code,
tests, real-model outputs, and the Product Owner-facing account. The
[root SRS](../../docs/srs.md) still requires immutable raw transcription,
reversible correction, topic coverage, and model-response validation;
the [architecture](../../docs/architecture.md) now identifies the staged
pipeline as an implemented experiment rather than an unbuilt proposal.
The [test profile](../../docs/test-profile.md) and [Sprint setup](sprint_2_setup.md)
still select the prescribed six gates. The [accepted design](sprint_2_design.md)
retains the failed one-call concept and the approved correction/coverage
repair. The [implementation record](sprint_2_implementation.md) now
states the final AMI and Sejm results, all staged model prompt templates,
the topic-meaning failure, and the operator correction boundary. The
[functional test record](sprint_2_tests.md) links the six gate logs and
the [controlled trial](tests/multistage_minutes_trial_20261004.md).
The [README](../../README.md), [user manual](user_manual.md),
[handover](sprint_2_handover.md), and [Product Owner brief](sprint_2_increment_demo.md)
all identify the content blocker and link the 3-slide
quality review (`sprint_2_quality_review_20261004.pptx`, historical version in Git). The
[progress board](../../PROGRESS_BOARD.md) was read: Sprint 2 and
PBI-011.5 remain under construction, consistent with failed natural-meeting
content review; no status transition is claimed here.

The final 30B staged model runs used unchanged saved real-meeting ASR
records. AMI kept 217/217 segments and assigned 21/21 reading utterances;
Sejm kept 801/801 and assigned 32/32. Manual claim-level citation review
passed only 2/5 AMI and 2/4 Sejm topic summaries. The Sejm output found
one of two explicit decision signals in the saved excerpt. Thus source
and schema gates passed while factual quality failed. Earlier failed
stage attempts and different candidate outputs remain under the trial's
evidence directory. No operator word correction was applied in the
measured runs. The short unassigned Sejm continuation was proposed for
one reading utterance by the final deterministic cleanup, but its speaker
identity has not been checked against audio.

Verification for this audited experiment: `swift test` passed 13
integration and 18 core tests; the release adapter built and the focused
`PipelineValidationTests` passed. The prescribed runner passed A1, A2,
A3, B1, B2, and B3 at stamp `20261004_103418`; its individual logs are
linked from the functional test record. The quality deck passed PPTX
package, layout, font, and reimport validation and all three rendered
slides were visually inspected. A local Markdown-link check examined
392 links across the edited narrative documents and found zero missing
targets. `swift run meeting-summarizer inspect-cleanup` on the staged
Sejm record returned 16 proposals and 32 reading utterances; the
manual's `jq` inspection shape was also executed. The trial runner passed
Python compilation, the editable draw.io file parsed as two pages, and
`git diff --check` passed. At the time of this experiment audit, the
commands had not yet been rerun as one fresh 30B handover journey. The
later single-command rehearsal at the top of this file completed that
CLI run; operator audio review and the Product Owner handover decision
remain pending. The current candidate is an architecture result, not a
participant-ready minutes capability.

The bounded staged-minutes experiment is ready for an evidence commit.
This commit will record tested prototype code, both successful and failed
model attempts, the manual content failure, and reconciled sprint material
together. It does not complete PBI-011.5 or change the sprint state.
