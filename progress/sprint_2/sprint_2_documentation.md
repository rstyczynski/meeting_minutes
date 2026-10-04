# Sprint 2 — Documentation review

Status: presentation set prepared for Product Owner inspection in managed mode; documentation approval and sprint completion remain pending. The reopened FR-11 implementation, bilingual benchmark, and corrected parent quality gates have passed. The natural-meeting minutes defect is a documented prototype finding, and the generated drafts are not accepted as correct. The root plan keeps Sprint 2 in Progress.

## Purpose of this review

The RUP Documentor's final responsibility is to validate the documentation
as a usable account of the increment. That includes completeness for each
assigned PBI, working copy-paste commands with prerequisites and expected
results, an error case, consistent status and paths, readable interpretation
of test evidence, and working links from PBIs to design, implementation,
tests, and benchmark. A Product Owner should be able to reproduce the
contract-level workflow and understand model-quality findings from these
documents before inspecting raw logs. In managed mode, the Documentor seeks
Product Owner approval before declaring this review complete.

## Scope and evidence

The active Sprint 2 plan assigns PBI-011 and PBI-018. PBI-011 comprised five originally completed sprint-scoped children: core and store, CLI capabilities, fixture and correction, review player, and local-model integration. The accepted FR-11 amendment added PBI-011.6 for bilingual transcription. Each original child, PBI-018's initial benchmark, and the original PBI-011 parent passed a distinct six-gate run and received a local completion commit. PBI-011.6 and the PBI-018 language extension have their own corrected-wrapper passing runs and commits. The reopened PBI-011 parent has also passed six corrected-wrapper gates. The [functional test record](sprint_2_tests.md) links the retained gate logs in the [test evidence directory](tests/), including failed attempts, successful reruns, and the path verification after moving evidence. The [documentation audit](sprint_2_documentation_audit.md) records reconciliation before each completed increment commit. After the Product Owner reopened minutes quality, the [progress board](../../PROGRESS_BOARD.md) marks Sprint 2, PBI-011, and PBI-011.5 `under_construction`; completed sibling children and PBI-018 remain `tested`.

The [setup and analysis](sprint_2_setup.md), [accepted design](sprint_2_design.md), [implementation record](sprint_2_implementation.md), [functional test record](sprint_2_tests.md), [benchmark report](ami_asr_benchmark.md), [AMI fixture record](ami_es2002a_fixture.md), [SRS](../../docs/srs.md), [architecture](../../docs/architecture.md), [test profile](../../docs/test-profile.md), and [README](../../README.md) were reviewed together. The Product Owner's accepted CLI amendment and low-quality-audio design revision are reflected in the implementation and tests. The implementation record provides a real-model command, model prerequisites, readable transcript output, expected result, and an error example. The functional test record contains the synthetic command sequence and its `cat`/`jq` contract result. The natural AMI meeting supplies measured model behavior.

The benchmark gives the decision-facing comparison, raw evidence locations, scoring method, and limitations. FluidAudio had lower word error rate than whisper.cpp on the tested AMI headset mix, while speaker clustering still merged the affected participant with another person. The local MLX adapter executed with a staged model and local Metal library, but natural-audio minutes invented actions and questions. The later FR-11 measurement shows both multilingual candidates producing English and Polish text from fixed referenced read speech. Parakeet v3 had lower error on both language subsets. Multilingual Whisper's Metal path failed on this host, requiring CPU mode; both engines omitted the English portion of an exploratory `auto` language-switch splice. The subsequent [Sejm PDF comparison](tests/polish_sejm_pdf_transcription_review_20261002.md) establishes recognizable Polish meeting turns and decision content but also names, acronyms, words, and numerical units requiring correction. Sprint 3 PBI-012 analyzes these measurements before selecting architecture changes. Reliable affected-person identification, an operator comparison of alternate input, natural minutes accuracy, bounded review-player replay, portable MLX packaging, and representative Polish meeting WER remain open limitations. No production-quality claim is made for them.

## Traceability and verification

The backlog directories [PBI-011](../backlog/PBI-011) and [PBI-018](../backlog/PBI-018) link to the setup/analysis, design, implementation, tests, this review, and the benchmark. The original final documentation check found no broken local Markdown links, no tables in narrative documents, and no `exit` command in copyable code blocks. The required table remains in the progress board. The original six parent gates passed on 2026-10-01 with stamp `20261001_172551`; the reopened parent passed six corrected-wrapper gates with stamp `20261001_213621`. The FR-11 final audit checks the revised commands and artifacts below.

The earlier Phase 5 preparation review confirmed that setup, accepted design and test
specification, implementation, functional tests, benchmark, and this review
all exist. Every traceability symlink for both assigned PBIs resolves. All
98 gate logs retained at that review had individual links under the test record's Artifacts
heading; the logs that falsely appeared to pass before the wrapper fix are
identified there as failed attempts, with the corrected passing replacements.
The six final parent logs end with explicit PASS. A fresh local-link scan of
16 README, Plan, board, docs, and Sprint 2 Markdown files found zero broken
links and zero tables in narrative documents. Copyable Markdown blocks
contain no `exit` command. Shell syntax and the two Python experiment
scripts checked cleanly, the 20-result and four-result JSON files parse,
and `git diff --check` passed before the parent completion commit.

The newly documented Polish command was executed with the staged Parakeet
v3 model and produced record `84C30D16-200F-4D48-9569-F709F30B359B`.
The adjacent `cat`/`jq` command printed `Requested: pl`,
`Model: parakeet-tdt-0.6b-v3`, and transcript words beginning
“Jakiekolwiek korekty lub żądania.” The README points to that walkthrough
and the decision-facing benchmark. PBI-011.6, the PBI-018 language
extension, and the reopened PBI-011 parent have separate local completion
commits `3717845`, `caa51be`, and `0dd3ea6`; no remote push occurred.

The Product Owner's review then exposed a failure of this quality gate: a
command block described as a real CLI example used literal
`/absolute/path/to/...` placeholders. Running it correctly returned
`Media file does not exist`. The Documentor should have rejected that block
before claiming copy-paste validation. It has been removed. The
implementation record now directs readers first to the real-model benchmark
and its decision-facing findings. It also gives actual staging and
transcription commands for the licensed Polish sample. The test record
contains the separately labeled synthetic CLI check, which establishes
only CLI and storage behavior. The real-model example states that audio and
weights must be staged first. The synthetic commands were rerun in sequence
for this correction: record
`EC9EB600-9DDC-4CD9-9009-A02C9EDC2387` retained five turns, the Ada
chair assignment, the corrected first turn, and four review items. The
Polish example and its `cat`/`jq` output had already run on staged assets.
The deliberately missing-media command was rerun and returned status 2 with
`Media file does not exist`. A final check of eight executable shell blocks
in the README, implementation, and test records found no placeholder paths,
no `exit` commands, and no shell syntax errors. All 16 reviewed Markdown
files had valid local links and no narrative tables; all traceability links
resolve, and all 98 gate logs remain linked.

The Product Owner then directed that the synthetic command sequence belong
only in the functional test record. It was moved there with its expected
human-readable result. The implementation instructions now contain the
real-model run and no test-only reference option. The README points readers
to each document for its distinct purpose.

The Product Owner then specified the missing acceptance walkthrough:
English and Polish transcription, weak-audio handling, manual name
assignment, and minutes. The implementation record now follows those four
steps with actual settings, staged asset checks, commands, readable saved
output, and observed limitations. The full AMI meeting generated 2,576
English segments and 16 low-speech-level warning ranges; one Polish clip
generated 15 segments; manual assignment persisted a demonstration name;
and a separate 120-second natural AMI excerpt generated six MLX review
items whose content failed review. The functional test record contains the
record IDs and evidence distinction. The walkthrough also explains the
other delivered prototype behavior and what remains unvalidated.

The documentation is prepared for Product Owner review as prototype decision
support: source data, commands, measurements, observed failures, and
traceability are available in readable documents. The synthetic walkthrough
cannot validate any model. The small FLEURS subset supports an initial
English/Polish feasibility decision, while reliable low-quality participant
identification, natural minutes accuracy,
and within-recording language switches remain open. No remote push was made.

The Product Owner rejected those single-speaker Polish sentences as meeting
demo inputs. A ten-minute excerpt from an [official multi-person Sejm
committee sitting](polish_sejm_meeting_fixture.md) was then staged and run
through the real CLI. It produced 802 timed Polish segments, three speaker
clusters, and a chair name supported by the official sitting record for
the opening turn. The first minutes run failed on a speaker label used as
a source ID. A citation and owner-validation repair made the command save
four draft items on rerun, but two items still fail source content review:
a request to present is called an action, and an open question was not
asked. The [test record](sprint_2_tests.md#polish-multi-person-meeting-correction--2026-10-02)
and [handover record](sprint_2_handover.md) give exact evidence. The Polish
meeting transcript has no whole-clip WER because the official written
record is edited and not time aligned.

A [30-minute Department of Energy meeting](doe_itiac_day2_fixture.md)
was also staged from the department's public recording and official
speaker-labeled transcript. Its direct CLI run saved 4,216 English segments
and eight anonymous speaker IDs. Qwen3-4B and a separately staged
Qwen2.5-7B alternative both failed to parse minutes output for this
longer input, leaving no review items. The 7B alternative also failed
source-content review on the shorter Sejm meeting. These are documented
as minutes-model benchmark failures, not ASR score changes; the [test
record](sprint_2_tests.md#doe-30-minute-english-meeting-and-second-minutes-model--2026-10-02)
and [benchmark](ami_asr_benchmark.md#polish-meeting-minutes-quality-check)
state the comparison and limits.

## Approval

The prior documentation approval request was superseded by the FR-11 scope
addition. The Product Owner then introduced P9, a developer-led handover
before Phase 5 approval. The [single-command demo and presenter script](demo/README.md),
[user manual](user_manual.md), [slide
demonstration](sprint_2_increment_demo_pipeline_20261004_v2.pptx), and [handover
record](sprint_2_handover.md), with the [Product Owner
brief](sprint_2_product_owner_presentation.md), now present the runnable increment and its
failures. The Product Owner initially stated that the minutes defect blocked
delivery. The structural crash was fixed, and the later staged trial
measured the remaining content failures. The Product Owner subsequently
directed that these failures be presented as prototype conclusions and
next-work evidence, without accepting the draft minutes as correct.
The handover decision has not yet been recorded. In managed mode,
the Product Owner must explicitly review that package before the Documentor
may seek final documentation approval or close the sprint. No further
per-gate permission is needed to run the single test entry point,
`tests/run-sprint-gates.sh progress/sprint_2`.

## Evidence-first response gate update — 2026-10-02

The Product Owner approved an evidence-first minutes repair and requested
technical validation of every model response before downstream use. The
[SRS](../../docs/srs.md) now records NFR-06, the [design](sprint_2_design.md)
defines the checks and bounded repair, and the [implementation
record](sprint_2_implementation.md) includes the exact active and historical
model prompts. The [test record](sprint_2_tests.md#evidence-first-minutes-and-response-gate--2026-10-02)
links the controlled checks and six passing Sprint gates. The earlier [14-slide
presentation](sprint_2_increment_demo_initial_20261002.pptx) includes the response gate and
its real Sejm failure. The [manual](user_manual.md) and [Product Owner
brief](sprint_2_product_owner_presentation.md) now distinguish historical
drafts from the active validator's rejected output. A passing technical gate
does not establish useful minutes; current 4B and 7B real-meeting trials
still prevent acceptance of dependable minutes.

## Larger local model trial — 2026-10-03

The fully staged Qwen3 30B candidate was run against the same saved AMI
and Sejm transcripts with the active evidence-first gate. The
[decision-facing trial](tests/qwen3_30b_minutes_trial_20261003.md)
links every raw response and saved record and reviews the cited words.
AMI yielded one technically valid quotation of the meeting brief after
repair; Sejm repeated malformed JSON and left zero draft items. The
[benchmark](ami_asr_benchmark.md#evidence-first-gate-and-larger-local-model-candidate),
[tests](sprint_2_tests.md#evidence-first-minutes-and-response-gate--2026-10-02),
[implementation](sprint_2_implementation.md), and [handover](sprint_2_handover.md)
now give the same outcome. The 30B trial does not change the product
default, the unvalidated minutes quality, or pending Product Owner walkthrough.

## Current reading-policy handover correction

The [current pipeline deck](sprint_2_increment_demo_pipeline_20261004_v2.pptx), [implementation pipeline](sprint_2_implementation.md) and [segmentation guide](transcript_segmentation.md) explicitly separate ASR, diarization, Swift grouping and LLM minutes. The guide enumerates every implemented reading control, its default and validation rules. The CLI example was exercised on a copy of the real record and retains the active record unchanged. The [test record](sprint_2_tests.md) distinguishes passing configuration/source checks from pending native playback and unimplemented semantic/acoustic reassessment. Earlier deck versions and model evidence remain historical.
