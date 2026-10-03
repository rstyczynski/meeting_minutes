# Sprint 2 — Architecture-risk prototype design

Status: Accepted

The original combined `import` design below records work already built. The
Product Owner approved separate `transcribe`, optional `recognize`, and
optional `summarize` commands on 2026-10-01. Their revised contract and test
coverage are in [the accepted change](sprint_2_proposedchanges.md). The
FR-09/FR-10 low-quality-audio experiment was separately approved and added
below. The three-command contract governs the remaining construction.
The Product Owner then added FR-11 English and Polish transcription to the
active sprint and approved its design amendment on 2026-10-01. The earlier
accepted design and completed English measurements remain historical evidence.

## Approved minutes-quality recovery amendment — 2026-10-02

**Scope:** PBI-011.5, BUG-2 and BUG-3. The Product Owner approved this
evidence-first design on 2026-10-02. It retains the
accepted separate `summarize` command and local MLX adapter. The [new failure
diagnostic](tests/doe_minutes_failure_diagnosis_20261002.md) establishes
truncated 4B JSON on the 30-minute DOE input, while the [fresh Sejm and AMI
records](sprint_2_tests.md#product-owner-presentation-rehearsal--2026-10-02)
show that valid JSON can still contain unsupported minutes claims.

The design changes `summarize` from free-form generated assertions to
evidence-first draft selection. The model proposes an item type and exact
source IDs, plus a short source quotation. The core resolves the IDs to
saved transcript segments and accepts the item only when the quotation is
an exact normalized substring of the cited text. The saved review text is
the transcript quotation, not a model paraphrase. Each item retains the
source IDs and time range. An uncited summary is never saved as a review
item; the operator instead sees selected source excerpts with citations.
The output is explicitly a **draft for human review**, not a claim that
the transcript or classification is correct.

### Model-response validation gate

Every LLM response crosses a gate before another product step can save or
use it. The adapter checks for one complete JSON object, required fields
and types, bounded item and citation counts, existing source IDs, and
verbatim quotations within the cited chunks. A technical failure produces
a repair prompt naming the failed checks and the required schema. The next
response is validated again. At most two repair prompts are sent; a third
invalid response causes an explicit error and leaves the prior record
unchanged.

The core independently validates expanded persisted segment IDs, source
ranges, quotation containment, and conservative item-type signals. It
withholds unsupported candidates even when the model's JSON is valid.
Nothing advances to saved `reviewItems` or a later product stage merely
because a response looks plausible. The operator sees retained cited
drafts, a withheld-candidate count, or an explicit failure. The original
audio still needs human review because transcript words and semantic type
checks can be wrong.

The Sprint 2 demonstration will show an invalid response being rejected
or repaired, a supported source-linked Sejm decision if the real model
produces one, and an unsupported action or question withheld. A clean
transcript with no dependable summary remains a visible limitation.

The first conservative type checks are intentionally asymmetric. A
`decision` candidate must include explicit acceptance, rejection, vote,
or no-objection language in its cited quotation. An `action` must include
an explicit future commitment by a named or neutral participant, not an
invitation to present the next topic. An `openQuestion` must quote an
actual interrogative turn and must not be generated from a statement.
Candidates that do not meet those checks are withheld and counted in a
diagnostic result. The operator can still inspect the transcript; absence
of an item does not assert that no decision, action, or question occurred.
The implementation will keep the original record unchanged if generation
or validation fails. No silent fallback to the old free-form items is
permitted.

To bound the proven output-size risk, the first supported adapter invocation
will reject a transcript longer than ten minutes with an explicit
`minutes input exceeds prototype limit` error before model invocation. Ten
minutes is the longest real meeting input for which this sprint obtained
structured output, not a demonstrated quality threshold. The existing
30-minute DOE record must then return that explicit error and preserve its
transcript; it must not produce empty minutes while appearing successful.
Reliable windowed long-meeting generation remains a separate architecture
experiment. The adapter will retain a bounded diagnostic copy of malformed
response text under the sprint test store during experiments, with source
media and model paths recorded. Product records will not contain raw model
debug text. For a release design, diagnostic retention and privacy need a
separate decision.

The implementation candidate is a small new evidence validator in
`MeetingCore` plus a narrower MLX response schema in
`MeetingMLXMinutes`. `MeetingCore` expands model chunk IDs to persisted
segment IDs, validates quotation containment and type signals, then writes
only accepted draft items atomically. The adapter limits candidate count,
response size, and source IDs; the core's deterministic checks remain the
authority when the model ignores instructions. Existing fixture-derived
contract behavior remains separate from real-model evaluation. The direct
debug-binary launch difference is contained by the documented `swift run`
path; the proposal does not assert a Metal or sandbox root cause.

The proposed acceptance evidence is a clean-store run on the existing AMI
and Sejm audio through the exact manual commands. The Sejm positive-opinion
turn must be retained as a cited, inspectable decision. The unsupported
Sejm action and invented question, and the AMI remote-control and inferred
setup questions, must be withheld. Every saved item must quote its cited
transcript text and lead to the correct range in the record. The 30-minute
DOE record must receive the explicit size-limit error without losing ASR or
speaker data. A focused unit set will check exact quotation containment,
unknown IDs, false type signals, output preservation, and the ten-minute
boundary; an integration check will exercise `summarize` through the CLI.
After those pass, the six Sprint gates and a fresh real-model rehearsal
must be recorded. The source-grounded output will still require Product
Owner inspection of the audio and transcript before handover acceptance.

This amendment changes the meaning of generated minutes. Its strict checks can omit legitimate
items, particularly when ASR wording or punctuation is poor. If the Product
Owner prefers broad abstractive minutes, that is a different quality-risk
decision and should be made explicitly rather than inferred from a passing
JSON schema check.

### Recovery test specification

**UT-11** tests quotation containment, exact source resolution, and
type-specific rejection for decisions, actions, and questions on small
English and Polish segment sequences. It asserts that a false question
from a statement and an invitation to present are withheld, while an
explicit positive-opinion turn is retained. **UT-12** tests the ten-minute
boundary and atomic preservation of an existing record when minutes input
is rejected. **IT-11** runs the separate CLI `summarize` operation against
a fixture adapter response with exact citations and verifies persisted
source ranges and neutral labels; malformed or unsupported output must
leave the prior record usable. The existing real AMI, Sejm, and DOE inputs
remain the model-quality experiments, not synthetic test substitutes.
The Sprint 2 A1–A3 and B1–B3 gates are rerun after implementation.
**UT-13** injects malformed JSON, missing fields, unknown IDs, excessive
citations, and a quote mismatched to its cited text into the response gate.
It checks specific reasons, a bounded repair attempt, and final rejection.
**IT-12** checks that final model-validation failure leaves an existing
transcript and speaker labels unchanged. Controlled adapter responses
trigger these cases; test results do not depend on a model misbehaving on
command.

## Approved FR-11 amendment — PBI-011.6 bilingual transcription

Status: accepted by the Product Owner on 2026-10-01. PBI-011.6 is a
sprint-scoped child of PBI-011. It depends on the completed CLI and local
adapter children PBI-011.2 and PBI-011.5. Its bounded outcome is a transcript
command with an explicit `--language en|pl|auto` option, persisted requested
language and model provenance, and a clear error when the configured model
cannot serve the requested language. It does not change the optional
recognize or summarize workflow.

Omitting `--language` retains the prototype's English default for existing
commands. `auto` is a deliberate request for automatic detection and requires
a multilingual model; it is not inferred from the user's location or system
language.

The first multilingual candidates are FluidAudio with Parakeet TDT 0.6B v3
Core ML and whisper.cpp with a multilingual Whisper model. The current
Parakeet v2 and Whisper base.en weights are English only and must never be
used silently for `pl`. The [FluidAudio source](https://github.com/FluidInference/FluidAudio/blob/main/Documentation/ASR/GettingStarted.md)
distinguishes v2 and v3; [NVIDIA's v3 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)
lists English and Polish. [Whisper's documentation](https://github.com/openai/whisper/blob/main/README.md)
distinguishes `base.en` from multilingual `base`. Pin and record the actual
weight revision, hash, license, executable version, and local path before
using either candidate. A model's published language list establishes only
candidate capability; Sprint 2 must measure actual local outputs.

For whisper.cpp, `--language en` and `--language pl` pass the corresponding
language code to its CLI; `auto` requests model detection. For FluidAudio,
the adapter loads v3 when Polish or automatic language handling is requested
and passes its available language hint where applicable. The pinned
FluidAudio API describes the hint as script-aware token filtering, so it may
not distinguish English and Polish, which both use Latin script. The UI and
record must not claim a guaranteed detected language from that hint. The
adapter will record requested language and selected model separately, fail
on unsupported combinations, and preserve the existing record on failure.

Use a pinned, licensed set of natural English and Polish utterances with
reference text and multiple speakers, staged outside Git if necessary. The
[Google FLEURS dataset](https://huggingface.co/datasets/google/fleurs) offers
`en_us` and `pl_pl` splits under CC BY 4.0 and downloadable per-language
Parquet files; select a small fixed subset from both rather than fetching the
whole corpus. [Mozilla Common Voice Polish](https://mozilladatacollective.com/datasets/cmu5wsxwp00e0nq07m8v0274j)
is a CC0 alternative but its full archive is large and forbids re-hosting.
Document source revision, clip IDs, reference text, checksums, attribution,
audio conversion, and scoring normalization. Compare both multilingual
engines on the same selected audio within each language.
Measure word and character error, output language, execution time, and
offline behavior; report each sample and aggregate results without inventing
a production threshold. A small mixed-language sample is exploratory and
must be labeled separately from the two-language acceptance evidence.

The proposed test specification adds **SM-3** for help and invalid language
rejection, **UT-10** for model/language compatibility and provenance,
**IT-10** for persisted English and Polish transcript flow plus preservation
on a missing or incompatible model, and **EXP-7** for both real multilingual
adapters on common licensed English and Polish references. All six Sprint 2
RUP gates run for the completed child; PBI-018 reruns the comparative
measurement and its own gates after the bilingual evidence is added. This
amendment validates the two required languages at prototype level. It does
not set production accuracy thresholds or certify in-meeting code switching.

## Approved CLI revision

Status: Accepted by the Product Owner on 2026-10-01. The Test Architect added
SM-2, UT-7–9, and IT-7–9 skeletons before revised CLI construction.

The Product Owner confirmed the transcription boundary on 2026-10-03:
local ASR supplies an ordered sequence of text with start and end times.
The Swift adapter converts that output into validated transcript segments,
and MeetingCore creates the persistent meeting-record JSON. The ASR model
is not prompted to invent JSON, source IDs, decisions, or minutes. An
adapter may use its engine's JSON output mode as a transport format; that
does not make JSON the user's transcript format or an LLM generation task.
This clarifies the accepted CLI design and does not change the minutes
prompt or its approval status.

`transcribe <local.wav> --transcriber fluid|whisper` will validate local
media, run the selected local ASR adapter, and atomically create one record
with timed transcript segments, backend provenance, and neutral or unknown
speaker labels. It will not create minutes. The existing store contract and
record ID will remain the handoff to the review player.

`recognize <record-id> --diarizer fluid` will optionally assign neutral
speaker turns to that same record from local audio. `recognize name` will let
the chair assign a display name to an existing speaker ID, and `recognize
move` will reassign a segment while preserving its source range. Automatic
person-name suggestions from media or local voice references remain the
nice-to-have FR-08, outside this prototype's MVP acceptance. If recognition
is skipped, a summary can still use neutral or unknown labels.

`summarize <record-id> --summarizer mlx` will read the saved transcript and
current chair assignments, run a local LLM, validate cited source segments,
and atomically add review items without transcribing again. A missing model,
unknown record, invalid source ID, or failed generation must leave the prior
record usable. Detailed rules for changes after a summary and reruns are
deferred to later requirements refinement, as the Product Owner directed.
The complete accepted command syntax and error cases are recorded in
[the change proposal](sprint_2_proposedchanges.md).

The accepted test amendment is: **SM-2** checks that help advertises all
three commands. **UT-7** checks a transcript-only result and unchanged store
on a missing-media error. **UT-8** checks name assignment and segment movement
without losing source ranges. **UT-9** checks that minutes validation rejects
unknown source IDs and that no recognition is needed for neutral-label
summary. **IT-7** executes the three commands in separate processes against
one synthetic fixture and one store, checking JSON after each step. **IT-8**
skips recognition and confirms the optional summary retains neutral labels.
**IT-9** checks unknown record and missing local model failures preserve the
last valid record. Executable skeletons and `new_tests.manifest` entries are
prepared before construction. Real-model quality remains under PBI-018
experiments.

## Objective and boundary

Exercise the accepted macOS-first architecture with an executable Swift
prototype, then measure the risks it cannot settle with deterministic tests.
This design covers PBI-011 and PBI-018 in `PLAN.md`. The prototype is
provisional evidence; Sprint 3 will decide whether any component is fit to
retain for Construction. No live capture, alerts, visual extraction,
cloud service, participant account, or production release is in scope.

The accepted SRS and architecture govern this design. No particular LLM is
already selected.

## Programming language and runtime boundary

The accepted Sprint 1 architecture selects **Swift** for the product prototype:
`MeetingCore`, the `meeting-summarizer` CLI, the local store, model adapter
contracts, and the macOS review application. SwiftUI supplies the review UI;
Swift Testing verifies Swift behavior. This keeps the shared core usable from a
future iOS adapter and matches the accepted `swift build` and `swift test`
quality gates. The Sprint 2 design applies that existing choice; it does not
silently select a new product language.

Apple created Swift and remains a major contributor, but Swift is an
[open-source project with community governance](https://www.swift.org/about/).
The language and core tooling are published under Apache 2.0 with a runtime
library exception. Choosing Swift does not require an Apple-owned proprietary
language license.

The selected open-source engines retain their native implementations behind
Swift adapters. In particular, whisper.cpp is C/C++ code called by the Swift
prototype through a local macOS process initially; a future native binding
requires separate portability evidence. Python runs only the offline test
fixture generator in `tests/fixtures/`. It is not installed or invoked by the
product at runtime. No product feature depends on a Python service.

If the Product Owner wants to revisit Swift before construction, the accepted
architecture and test profile must be revised together with this design.

## PBI-011 — Executable architectural prototype

### Proposed child PBIs

These are sprint-scoped refinements of PBI-011. They do not change the root
backlog or sprint assignment. Product Owner approval of this decomposition is
required before construction.

#### PBI-011.1 — Core and local store

Create a Swift Package with the portable `MeetingCore` record, source-range
and adapter protocols, and atomic local record store. Acceptance requires
`swift build`, core unit tests, and reload of a persisted synthetic record
after a new process starts. The core must not import SwiftUI or AppKit. This
child depends on the accepted SRS and architecture.

#### PBI-011.2 — CLI import

Make `meeting-summarizer` validate a local media path, select the configured
transcription backend, invoke the shared import use case, and print an opaque
record ID. Acceptance requires an offline smoke check: supported synthetic
input creates a record, while nonexistent or unsupported input or an invalid
backend fails without overwriting source or records. This child depends on
PBI-011.1.

#### PBI-011.3 — Derived record and corrections

Implement and document the synthetic meeting fixture generator under
`tests/fixtures/` as part of Sprint 2 construction. It must generate a
16 kHz mono PCM WAV and paired reference JSON from invented two-speaker
dialogue, including word text, turn times, speaker IDs, a decision, an
action, and an open question. Check in the generated pair and regeneration
instructions. Acceptance requires a successful regeneration check with
nonempty audio, valid turn ranges, and references that resolve to the
generated turns.

Fixture-backed local transcription, speaker, and minutes adapters then create
timestamped segments, neutral labels, decisions, actions, and optional
source ranges; chair corrections persist. Synthetic integration tests must
show source-linked output and correction after reload. Fixture adapters are
contract tests, not model-quality evidence. This child depends on PBI-011.1
and PBI-011.2.

#### PBI-011.4 — Review player

A SwiftUI review executable opens a CLI-created ID from the same store,
displays the record and local media, and seeks to a selected source range.
Acceptance requires a macOS build, a manual local run, and a synthetic
record-opening integration test. This child depends on PBI-011.1 through
PBI-011.3.

#### PBI-011.5 — Local-model integration

Separate adapters exercise **both selectable transcription backends**,
FluidAudio and whisper.cpp. FluidAudio's diarization path supplies neutral
speaker turns for either backend. MLX Swift LM with Qwen3-4B-Instruct-2507
4-bit exercises minutes generation behind the `MeetingCore` contract.
Acceptance requires reproducible runs with pinned code and model revisions,
local-only inference, and timestamped transcript and source evidence;
otherwise record explicit blocked results. This child depends on PBI-011.1
through PBI-011.3. PBI-018 benchmarks its working model adapters.

### Prototype data flow

```mermaid
flowchart LR
    Media[Local recording] --> CLI[CLI transcribe, recognize, summarize]
    CLI --> Core[MeetingCore use cases]
    Core --> Models[Local adapter contracts]
    Models --> Store[Atomic local record store]
    Store --> UI[SwiftUI review by record ID]
    UI --> Store
    UI --> Media
```

`MeetingRecord` uses a local UUID, immutable source URL or bookmark reference,
ordered `TranscriptSegment` values with stable IDs and time ranges, neutral
speaker IDs, chair label and attribution corrections, and `ReviewItem` values
for summary, decisions, actions, and open questions. `ReviewItem.sourceRange`
is optional; a participant-facing rendering omits references. Corrections
append a change and rebuild the derived view; they do not alter the source.

The CLI and review player share an explicit local store path in prototype
configuration, defaulting to the operator's Application Support directory.
The store writes a temporary record and atomically replaces the old record.
Failed processing preserves the source and previously completed record. A
future sandboxed app needs separate validation of shared-directory access.

### Configurable transcription backend

The operator can select `fluid` or `whisper` in a local settings file. The
CLI's `--transcriber fluid|whisper` option overrides that setting for one
import. The proposed default is `fluid`; a missing model or unavailable
backend causes an explicit local error rather than silently switching to
another engine. The settings file also identifies the local model directory
for each engine. Runtime processing never downloads a missing model.

`MeetingCore` owns the backend selector and a common transcription protocol;
platform adapters own FluidAudio and whisper.cpp calls. Both adapters must
return the same timestamped `TranscriptSegment` contract. The record stores
the chosen backend, model revision, and processing parameters so the
operator can interpret and reproduce the result. FluidAudio diarization is
independent of the transcription choice; align its timed speaker turns with
either transcript, and leave uncertain assignments as neutral labels for
chair correction. The prototype may invoke whisper.cpp as a local macOS
process; iOS packaging and a native binding remain separate validation risks.

Configuration establishes a real user choice in the prototype. PBI-018
compares both backends on the same approved audio. Sprint 3 PBI-012 uses the
results to recommend how this choice should appear in the Construction
release. An accepted shipping configuration and default belong in the
refined SRS and Construction plan.

The prototype records the selected input format and rejects other formats.
Initial synthetic tests use one small local audio format; additional codecs
are PBI-018 experiments, not implicit support claims. A fixture adapter keeps
all automated tests deterministic. It cannot count as proof of transcription,
diarization, or LLM quality.

### Feasibility and errors

Swift 6.3.3 is available on the working Mac. The accepted Swift Package,
SwiftUI, and Swift Testing structure supplies the build path. Media playback and seek
remain macOS adapter responsibilities. The design handles missing input,
unsupported codec, malformed timestamps, missing record ID, adapter failure,
and failed atomic write with explicit local errors. No path silently calls a
remote service or downloads a model. Only synthetic or approved recordings
may be used as validation material.

## PBI-018 — Benchmark technical decisions

PBI-018 is a separate Product Backlog item in Sprint 2. It benchmarks the
technical options exercised by PBI-011 using shared test inputs and recorded
quality and resource measures. Its results become input to Sprint 3 PBI-012;
they do not themselves settle every use case or the shipping architecture.

Validation separates contract correctness from real-model feasibility.
Synthetic fixture tests cover import, timestamps, source links, correction
persistence, CLI-to-UI record opening, failure recovery, and portable core.
Offline experiments then benchmark **both** selectable transcription engines,
FluidAudio and whisper.cpp, on the same pinned audio and reference transcript.
They also evaluate diarization and language models. The LLM produces minutes from
timestamped transcript text; it does not transcribe audio or identify voices.

### Validation recordings and reference data

The repository initially contained no exemplary meeting recording or annotated
transcript. PBI-011.3 implements the reproducible synthetic two-speaker
fixture generator, WAV output, and reference JSON under `tests/fixtures/`.
These files are the Sprint 2 implementation inputs for PBI-018, which runs
both backends and calculates scores from the same reference.
Synthetic speech alone cannot establish accuracy on natural meetings or
overlapping conversation.

For the representative comparison, obtain a small, explicitly approved local
sample of natural meeting speech with a reference transcript and speaker
annotations. The [AMI Meeting Corpus](https://groups.inf.ed.ac.uk/ami/download/)
is a candidate because it publishes meeting audio and annotations under
[CC BY 4.0](https://groups.inf.ed.ac.uk/ami/). Pin the meeting IDs, audio
channels, annotation release, and scoring normalization before running either
engine. Keep natural meeting audio, transcripts, metadata, and model weights
outside Git; record only fixture IDs, aggregate scores, and non-content logs
in sprint evidence, per `docs/test-profile.md`. If no approved natural sample
is available, report the representative benchmark as blocked and do not infer
real-world quality from the synthetic fixture.

Run both ASR engines on identical decoded 16 kHz mono audio. Compare word
error rate after one documented text normalization, word or segment boundary
error against aligned references, elapsed transcription time, peak memory,
and installed model footprint. Run each at least three times for runtime
variation. Record failed or missing words separately from downstream minutes
errors. Apply FluidAudio speaker turns to each transcript and compare speaker
attribution using the same reference. The evaluation report must show results
for each engine, its model revision and configuration, and measurement limits.
Sprint 3 analyzes the results and recommends a default; both remain
operator-selectable unless the Product Owner changes scope.

### FR-09 and FR-10 low-quality audio validation — approved revision

The Product Owner made low-quality audio and identification of an affected
participant a critical Sprint 2 validation requirement and approved this
design revision on 2026-10-01. The SRS contains separate use cases and
requirements for finding the affected participant (FR-09) and preserving
and reviewing the source and recovery result (FR-10). The approved natural
fixture is AMI ES2002a.
Its official data-problems record says participant 1 wore a headset
improperly, and the official meeting metadata maps participant 1 to
annotation speaker A. The mixed headset recording is the normal prototype
input; individual speaker tracks and annotations are evaluation references,
never hints supplied to the recognition pipeline.

For both ASR engines, score the unchanged headset mix against the same manual
reference, including errors in A's turns and in the other speakers' turns.
Compare speaker attribution and inspect whether the pipeline produces a
reviewable low-quality warning attached to an affected neutral speaker ID or
source time range. Use the manual annotation only afterward to measure how
well the warning covers A's affected speech and to count missed regions and
warnings on other speakers. If speaker attribution is uncertain, retain a
region-level warning without asserting an identity. Then run the mixed lapel
recording as a separate alternate-input condition and measure whether it
improves or worsens transcription and attribution. Preserve the original
recording and report uncertainty and resource costs.

The participant-recognition experiment passes only if the prototype itself
produces the reviewable warning and reference alignment shows it covers A's
degraded speech. Manual identification from the corpus metadata is not a
prototype result. FR-10 additionally requires that the original remain
available, the affected ranges can be replayed, and the alternate-input
result can be compared without destroying the prior result. If those
behaviors are absent or inaccurate, report the respective requirement as
failing validation with the measured model results. Sprint 3 will set
production thresholds and recovery policy from this evidence.

### Open-source library choices for the audio pipeline

For transcription, first test [FluidAudio](https://github.com/FluidInference/FluidAudio)
with a local Parakeet Core ML model. Its Swift package supports local ASR on
macOS and iOS and fits the accepted adapter architecture. Its convenience
loaders can download models on first use, so use manual local loading with
`ModelHub.offlineMode = true`. Verify the particular asset's license and
transcript timestamps.

For speaker turns, first test
[FluidAudio offline diarization](https://github.com/FluidInference/FluidAudio#speaker-diarization).
It offers timed speaker segments through a Swift-accessible offline path.
Measure overlapping speech, neutral-label stability, and the correction
workflow. Verify model-asset licensing and local-only loading. Diarization
does not establish a person's identity.

Make [whisper.cpp](https://github.com/ggml-org/whisper.cpp) the second
selectable transcription backend and compare it with FluidAudio on the same
audio. It supports local Whisper inference on macOS and iOS. Its CLI expects
16-bit WAV, so conversion may be needed; model footprint and Swift
integration still require measurement.

FluidAudio's [offline-mode documentation](https://github.com/FluidInference/FluidAudio#configuration)
shows explicit refusal of network fetches and manual loading from a local
directory. Prepare pinned weights before disconnected evaluation, keep them
outside Git, and fail clearly if an asset is missing. The library is
[Apache-2.0 licensed](https://github.com/FluidInference/FluidAudio/blob/main/LICENSE);
licenses of the chosen weights are checked separately. These are candidates
to measure, not an assertion that their quality already meets the SRS.

### LLM candidate analysis and experiment choice

[Apple Foundation Models](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
provides a native Swift API and guided generation for an on-device system
model. Availability depends on Apple Intelligence; a direct check on this
Mac returned `appleIntelligenceNotEnabled`. Apple's documented
[4,096-token session context](https://developer.apple.com/documentation/foundationmodels/managing-the-context-window)
also requires chunking for longer transcripts. It can be compared if enabled
later, but cannot be the sole Sprint 2 path here.

The primary PBI-011.5 minutes candidate is
[MLX Swift LM](https://github.com/ml-explore/mlx-swift-lm) with
`mlx-community/Qwen3-4B-Instruct-2507-4bit`. The Swift package has iOS and
macOS targets and a [local-directory loading API](https://github.com/ml-explore/mlx-swift-lm/blob/main/Libraries/MLXLMCommon/ModelFactory.swift).
The [conversion card](https://huggingface.co/mlx-community/Qwen3-4B-Instruct-2507-4bit)
traces to the [Qwen original](https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507),
lists Apache-2.0, and gives about 2.26 GB for weights. Actual RAM also
includes runtime and context cache. Prepare a pinned local copy before
disconnected tests. Meeting-minutes quality remains unproven.

Keep [llama.cpp](https://github.com/ggml-org/llama.cpp) with a local GGUF
model as a contingency if the MLX path cannot run or package acceptably. Its
[macOS Metal build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)
and [iOS sample](https://github.com/ggml-org/llama.cpp/blob/master/examples/llama.swiftui/README.md)
show a local path, but a particular GGUF artifact and Swift integration
would still need verification.

The primary choice is an **experiment candidate, not the shipping LLM**. It
is selected because it is a concrete, small quantized model with a traceable
source and a Swift-local runtime. The original Qwen model is listed as
Apache-2.0; MLX Swift LM is MIT-licensed. [Qwen model card](https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507), [MLX license](https://github.com/ml-explore/mlx-swift-lm/blob/main/LICENSE).
Before any distribution decision, verify the exact downloaded revision,
conversion provenance, dependency licenses, and required notices. The
working Mac is an M4 Pro with 48 GB memory, so success here alone cannot
establish performance on a lower-memory target Mac.

### Numbered arguments for the proposed library order

1. **FluidAudio first for transcription and speaker turns:** One Swift
   package exposes both tasks on macOS and iOS, so it can exercise the
   accepted adapter boundaries without introducing a Python runtime into the
   application. Its [project documentation](https://github.com/FluidInference/FluidAudio)
   includes batch ASR and offline diarization. This is an integration
   argument, not a quality result; Sprint 2 still measures word and speaker
   error on the same approved corpus.
2. **FluidAudio needs an explicit offline configuration:** Its convenience
   APIs can fetch weights when missing. The documented
   [`ModelHub.offlineMode` and manual loading](https://github.com/FluidInference/FluidAudio#configuration)
   offer a concrete way to reject that behavior at runtime. The experiment
   fails if any model asset is absent or a network fetch is attempted.
3. **whisper.cpp is the second selectable ASR backend:** It supports local
   Whisper inference on macOS and iOS through a C interface, giving the
   operator a choice and providing an independent quality and packaging
   comparison. Its
   [CLI documentation](https://github.com/ggml-org/whisper.cpp) also exposes
   a media-conversion cost for non-WAV inputs. It does not solve diarization,
   so FluidAudio diarization still supplies speaker turns in the prototype.
4. **MLX Swift LM plus quantized Qwen is the first minutes experiment:** The
   [Swift runtime](https://github.com/ml-explore/mlx-swift-lm) can load local
   model files, while the [4-bit conversion card](https://huggingface.co/mlx-community/Qwen3-4B-Instruct-2507-4bit)
   identifies an exact model artifact and approximate weight size. This
   creates a reproducible test of structured, source-linked minutes. It does
   not establish the model's meeting quality, peak memory, or suitability for
   lower-memory Macs.
5. **llama.cpp is the LLM contingency:** Its
   [Metal build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)
   and [iOS sample](https://github.com/ggml-org/llama.cpp/blob/master/examples/llama.swiftui/README.md)
   show another local inference path. It remains second because a particular
   GGUF model artifact and Swift integration have not yet been verified.
6. **Apple Foundation Models cannot be the only path:** A local API check
   returned `appleIntelligenceNotEnabled` on the working Mac. Apple's
   [availability documentation](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
   makes eligibility a runtime condition, and its documented
   [4,096-token context](https://developer.apple.com/documentation/foundationmodels/managing-the-context-window)
   requires chunking for longer meetings. It can be compared if available
   later, without making it a prerequisite for Sprint 2.
7. **Licenses and deployment are separate gates:** The library and base-model
   licenses are permissive in the cited sources, but converted weights and
   dependencies require exact-revision verification. No library enters the
   shipping architecture solely because it is open source or passes a fixture
   test. The decision requires offline, quality, resource, and iOS-path
   evidence from the PBI-018 benchmark and Sprint 3 PBI-012 validation.

### How the LLM will be exercised

1. Keep `MeetingCore` free of FluidAudio and MLX imports. Put both model
   adapters and weights in isolated experiment targets. Pin runtime and model
   revisions, record hashes, and keep weights outside Git. Dependency and
   weight preparation occurs before the offline run; the accepted
   `swift build` profile for the core and CLI must still work without a
   download.
2. Pass only transcript segments with stable IDs, timestamps, neutral speaker
   labels, and text to the LLM. Divide longer meetings into bounded chunks;
   summarize each chunk and merge structured outputs. Do not send raw audio
   or infer participant identities from text.
3. Request structured `summary`, `decisions`, `actions`, and
   `open_questions`. Each decision or action must cite input segment IDs.
   An owner is present only when explicitly stated in the cited text. Parse
   and validate the response; reject unknown IDs, malformed output, and
   unsupported owner claims. Derive source time ranges from cited segments,
   not from model-generated timestamps.
4. Run on synthetic and explicitly approved local transcripts, including a
   short meeting, a long meeting needing chunking, overlapping/uncertain
   speakers, explicit versus absent owners, and an unsupported claim trap.
   Annotate reference decisions and actions before scoring. Run with network
   connectivity disabled and capture evidence that the process needs no
   service during inference.
5. Record evidence in `progress/sprint_2/`: model and prompt revisions,
   fixture IDs, output with no real meeting content, schema validity,
   source-ID validity, decision/action precision and recall against the
   annotations, unsupported claims and owner assignments, elapsed time,
   peak memory, and model plus dependency footprint. Repeat a sample to
   observe output variability.

Record schema validity, source-citation validity, unsupported owner claims,
and offline execution for every output. Measure decision/action precision and
recall against the annotated corpus; report them without inferring meeting
quality from a generic benchmark. Record the target-device memory and time
budget if agreed, or its absence as a limitation. Sprint 3 decides whether
the evidence supports a Construction-ready recommendation or another bounded
Elaboration objective. A failed candidate does not promote the fixture
adapter automatically.

The audio experiments also measure diarization error, overlap behavior, and
downstream effect on minutes. They record per-model licenses, local asset
paths, packaging, run time, and peak memory. Media support, storage recovery,
and UI/CLI record opening are validated separately. A model requiring runtime
network access or an unusable license fails the local-only candidate gate. An
experiment may end `blocked` if no permissible local model or fixture is
available; it must not be reported as validated. Product Owner review is
required before treating any experiment candidate as the shipping choice.

## Sprint boundary

Sprint 2 delivers the executable prototype and PBI-018 comparison of both
transcription backends. The benchmark can test each completed adapter path as
it becomes available; it does not wait for every PBI-011 child to finish.
Sprint 3 PBI-012 validates critical assumptions and use cases using the
prototype and benchmark. PBI-013 through PBI-016 then refine requirements,
stabilize the architecture, assess the milestone, and plan Construction.
No Sprint 3 outcome is required to complete Sprint 2.

### Testing Strategy

#### Recommended Sprint Parameters

New-work tests and full-suite regression use smoke, unit, and integration
levels, as set in `PLAN.md`. There is no narrower regression scope because
this is the first code-bearing sprint. The smoke check runs the CLI; unit
tests cover core and store behavior; integration tests exercise synthetic
import and review paths. Operational checks cover local model execution,
offline network observation, grounded LLM minutes scoring, UI seeking, and
representative media and resource measurements. Automated fixture tests do
not substitute for those checks.

#### Unit Test Targets

Test the `MeetingCore` record model as pure values: ordered ranges, invalid
negative or reversed ranges, optional source links, and neutral labels. Test
atomic save and reload, missing IDs, and interrupted writes in a temporary
store. Test valid, nonexistent, and unsupported media URLs and adapter errors
with temporary files and fixture adapters. Test renaming and reassignment
across a reload without mutating the source. Feed the minutes validator
fixture responses with unknown segment IDs, malformed structure, unsupported
owners, and valid source ranges.
Check backend configuration precedence, invalid names, and explicit errors
when the selected engine or its local model is unavailable.

#### Integration Test Scenarios

Import a synthetic local fixture through the CLI into a temporary store, then
open its opaque ID in a new process and verify the timestamped record without
network use. Fixture adapters must produce a decision and action whose source
ranges resolve to the transcript and recording. A chair correction must keep
its label and attribution after process restart. The macOS review executable
must open a CLI-created ID and seek local media. A long synthetic transcript
must be chunked and merged without losing resolvable source segment IDs.
Verify the generated WAV and reference JSON as a paired fixture before these
tests: nonempty speech, expected PCM format, valid ordered turn ranges, and
minutes references to existing turns. Regeneration must fail if speech
synthesis produces empty audio.
Run the same synthetic audio through each selected backend and verify that
both results normalize to the shared timestamped segment contract and retain
the selected engine and model provenance.

#### Smoke Test Candidates

`swift build` confirms that core, CLI, and review executable compile.
`swift run meeting-summarizer --help` confirms the CLI entry point runs
without reading media or invoking a model.

Success means the prototype executes the bounded architectural paths and
PBI-018 reports actual benchmark evidence or explicit blockers. Passing
fixture tests alone does not authorize Construction.

## Test Specification

Sprint configuration: managed; new tests and regression at smoke, unit, and
integration levels. The project-specific commands in `docs/test-profile.md`
govern Swift execution; generic shell examples in the RUP submodule are not
the project's test commands.

**SM-1:** Build the package locally and run CLI help. Import usage must print
and the command must exit successfully. This covers PBI-011.1 and PBI-011.2.

**UT-1:** Reject invalid record ranges and retain optional source references
for PBI-011.1. **UT-2:** Reload a record and preserve its prior version after
a failed write, also for PBI-011.1. **UT-3:** Reject missing or unsupported
media without altering the source for PBI-011.2.

**UT-4:** Persist speaker rename and segment reassignment while preserving
source identity for PBI-011.3. **UT-5:** Reject unknown source IDs and
unsupported owners in minutes output for PBI-011.5.
**UT-6:** Apply CLI-over-settings backend precedence and reject an invalid or
unavailable backend without a silent fallback for PBI-011.2 and PBI-011.5.

**IT-1:** A synthetic CLI import yields an ID that opens a durable record,
covering PBI-011.2 and PBI-011.4. **IT-2:** Fixture-derived decisions and
actions resolve to local source ranges, covering PBI-011.3.
**IT-3:** Corrections remain after a fresh load, and the UI opens and seeks
local media, covering PBI-011.3 and PBI-011.4. **IT-4:** Long synthetic
transcript chunks merge without losing cited segment IDs, covering
PBI-011.5.
**IT-5:** Select FluidAudio and whisper.cpp separately for the same synthetic
audio, normalize both outputs to timestamped segments, and retain backend and
model provenance for PBI-011.5 and PBI-018.
**IT-6:** Generate and validate the PBI-011.3 synthetic WAV/reference pair;
reject empty synthesis output, invalid timing, or unresolved minutes
references before using it in PBI-018 experiments.

**EXP-1:** A pinned Qwen/MLX run returns structured minutes and valid source
IDs from approved local transcripts. Record quality and resources for
PBI-011.5 and PBI-018. **EXP-2:** Repeat inference with networking
disconnected and document any attempted access or model-loading failure.
**EXP-3:** Pinned FluidAudio ASR and diarization models produce timed text and
neutral speaker turns from approved local audio; record accuracy and
resources. Both experiments cover PBI-011.5 and PBI-018.
**EXP-4:** Run a pinned whisper.cpp revision and pinned local Whisper model
on exactly the EXP-3 audio. Score each engine against one reference transcript
using the same normalization, and compare time boundaries, runtime, memory,
and footprint. Repeat on an approved natural meeting sample; if absent, mark
representative accuracy blocked. This covers PBI-018.
**EXP-5:** Use AMI ES2002a's unchanged mixed headset recording for both
engines and the official participant-1-to-A mapping as a scoring reference.
Measure A's and other speakers' transcript and attribution errors separately;
measure whether prototype warnings identify A or affected source ranges,
including misses and warnings on other speakers. Run the mixed lapel audio
as a separate recovery condition and check original preservation and review
of suspect ranges. Record a pass or failure for FR-09 and FR-10 and all
limitations. This covers PBI-018 and the approved FR-09/FR-10 revision.

The Product Owner approved the CLI amendment on 2026-10-01. **SM-2** requires
help to advertise `transcribe`, `recognize`, and `summarize`. **UT-7** requires
a transcript-only result and no saved record on missing media. **UT-8**
requires chair naming and segment movement to preserve source ranges.
**UT-9** requires unknown source IDs to be rejected while a summary without
recognition keeps neutral labels. **IT-7** runs transcribe, recognize, and
summarize as separate processes on the synthetic fixture and verifies the
same record after every step. **IT-8** skips recognition and verifies that
optional summary uses neutral labels. **IT-9** checks that unknown records and
missing local model assets fail without altering the last valid record. These
cases trace to PBI-011.2, PBI-011.3, and PBI-011.5; IT-7 also exercises the
PBI-011.4 shared-store contract. The Test Architect adds runnable red
skeletons to the existing CLI/core test domains and registers them in both
the component manifests and `new_tests.manifest` before construction.

The real-model runs in PBI-011.5 and PBI-018 have a separate experiment record;
they cannot be made deterministic unit tests and are required evidence for
the milestone assessment. Runnable shell skeletons and the new-test manifest
are attached under `tests/` and `progress/sprint_2/`. At the original design
review, the unit skeleton run was red because `Package.swift` did not yet
exist. Construction has since added the package and Swift Testing bodies;
preliminary runs pass, as recorded in the implementation and test documents.
The project-specific commands in `docs/test-profile.md` remain the build and
quality gates.

## Review decisions requested

1. Accept or revise PBI-011.1 through PBI-011.5 as the prototype breakdown.
2. Accept FluidAudio and whisper.cpp as mandatory, selectable ASR backends
   for a same-audio benchmark, FluidAudio for diarization, and MLX Swift LM
   with the Qwen3-4B-Instruct-2507 4-bit conversion for the LLM experiment.
   Local weights are prepared outside Git; the LLM weights are roughly 2.26
   GB. This does not select shipping models.
3. Accept the checked-in synthetic seed and choose an approved natural
   meeting sample for representative scoring. AMI is a proposed public
   source; its media and annotations would remain outside the repository.
4. Accept the evidence and test scope. The recommendation for a shipping
   model and default backend returns for Product Owner review in PBI-012,
   with a target-device memory and processing-time budget still to be agreed.

Design approval status: Accepted by the Product Owner on 2026-10-01, including
the PBI-011 child breakdown. Construction may proceed.
