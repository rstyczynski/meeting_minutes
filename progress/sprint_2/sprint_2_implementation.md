# Sprint 2 — Implementation record

## Current processing pipeline and configurable reading turns — 4 October 2026

This PBI-011.5 correction supports PBI-011.4 operator review. The Product Owner requested removal of arbitrary 15-second and 1.5-second reading boundaries, explicit use of speaker changes, and configuration of every reading segmentation parameter. The accepted correction remains in the design record alongside the superseded attempts.

### 1. Audio to timed text: ASR

`transcribe` sends the local WAV and selected language to Parakeet through FluidAudio, or to Whisper through whisper.cpp. Parakeet produces token timings that our adapter converts into timed word parts; Whisper supplies timed fragments that may contain several words. Swift validates and saves these source parts in one local meeting record. Storage JSON comes from Swift. ASR receives no instruction to write JSON or discover topics.

### 2. Audio to anonymous speakers: separate diarization

Optional `recognize` calls FluidAudio's `OfflineDiarizerManager`, using local speech-segmentation and speaker-embedding models on the recording. It returns voice turns S1/S2/S3. Swift aligns each timed ASR part with the diarization turn having the greatest positive time overlap and saves the label. Neither the ASR model nor the minutes LLM performs this diarization. The weak-audio heuristic measures speech levels over those turns and records warnings. An anonymous label distinguishes a predicted voice cluster; the operator assigns a name separately with `recognize name`.

### 3. Source parts to reading turns: configurable Swift rules

`TranscriptCleaner` uses source text, times, speaker labels and any recorded operator text corrections. By default a change from S1 to S2 creates a boundary, and consecutive parts with the same effective speaker join without an elapsed-duration or pause cutoff. An explicitly labeled short turn keeps its label (`preserveSpeakerChanges: true`). The algorithm checks unassigned candidates against both neighbors and records a proposed bridge or one-sided join when configured proximity limits permit it. This proposal changes only the reading layer, preserving raw parts and labels. Setting `preserveSpeakerChanges: false` explicitly enables the prior brief-switch experiment.

All ten controls are configurable through this complete profile:

```json
{
  "transcriber": "fluid",
  "transcriptCleanup": {
    "grouping": "speakerTurns",
    "mergeUnassignedSegments": true,
    "proposeNeighborSpeakers": true,
    "preserveSpeakerChanges": true,
    "maximumCandidateWords": 1,
    "maximumNeighborGapSeconds": 1.5,
    "maximumOverlapSeconds": 0.15,
    "maximumOneSidedGapSeconds": 0.5,
    "maximumReadingBlockSeconds": null,
    "maximumReadingGapSeconds": null
  }
}
```

`grouping` selects speaker turns or source parts. `mergeUnassignedSegments` controls grouping of remaining unknown parts. `proposeNeighborSpeakers` enables neighbor proposals; `preserveSpeakerChanges` protects explicit diarization transitions. `maximumCandidateWords` controls brief-candidate size. The three neighbor/overlap/one-sided limits govern assignment proposals in seconds. The two optional reading limits are disabled by default; configuring them explicitly requests duration or gap boundaries. The [operator segmentation guide](transcript_segmentation.md) enumerates each control, its units, range, behavior, and a complete executable command with readable output. Mandatory source conservation and input validity checks cannot be disabled.

New transcription records save the resolved profile. `configure-cleanup` applies a profile to an existing record atomically. A changed profile invalidates derived minutes, topics and coverage while preserving source parts, names and corrections. Reapplying the same profile makes no write. Invalid configuration returns exit 2 and leaves the saved record byte-identical. CLI inspection, Meeting Review and multi-stage minutes use the same saved profile. Older records without a profile use current defaults. This profile does not reconfigure ASR decoding or FluidAudio's internal diarization model parameters.

### 4. Operator review and correction

Meeting Review displays the reading turns and offers source-part disclosure and bounded range playback. The operator can listen, correct text or speaker labels through the CLI and assign names. The application loads the saved profile when opened; restart it after applying a CLI change. Listening and semantic judgment remain human activities. Automated source conservation does not verify a voice or sentence meaning.

### 5. Prepared text to draft minutes: optional Qwen LLM

Multi-stage `summarize` prepares exactly the reading view selected by the saved profile. Qwen through MLX receives utterance IDs, text, times and available names. It discovers topics, assigns utterances to topics, checks coverage, summarizes each topic and extracts explicit items. The exact prompt documentation and historical failures below remain intact. The legacy single-pass experiment does not use this reading layer.

### 6. Quality gates before downstream use

The staged adapter checks JSON schema, IDs, coverage, exact evidence quotes, item structure and supported extraction. It sends bounded repair prompts when model output fails technical validation and rejects unresolved output instead of overwriting a saved record. These technical gates do not establish that every claim is semantically correct. Independent semantic boundary checks and acoustic reassessment of a proposed join remain open design work.

### Verification and interpretation

All six gates passed in the `cleanup_verified` run. UT-14 verifies every reading control and the two reported split regressions. IT-13 verifies persistence, changed-profile invalidation, no write on same profile or invalid input, and equality of CLI reading text/IDs and captured model input. A controlled Sejm copy produced four turns instead of 32 while preserving 802/802 source parts and every source word. Explicit alternative profiles produced 802 source-part blocks, 32 duration-capped blocks and six pause-capped blocks. The [receipt](tests/cleanup_configuration_20261004.json) provides commands and checks. These are segmentation measurements, not improved word error rate or speaker accuracy. Existing names in the active demo record remained untouched.

The [updated Product Owner deck](sprint_2_increment_demo_pipeline_20261004_v2.pptx) shows this pipeline on slide 3, separates the model jobs on slide 4, and enumerates the profile on slides 19–20. Native review automation could not attach to the currently running QA app (accessibility/screenshot calls timed out), so this correction does not claim a fresh successful GUI listening check. The build and CLI behavior passed. Live operator playback and Product Owner acceptance remain pending.

Status: executable bilingual prototype and staged-minutes quality experiment
measured. The minutes-content failure is an explicit prototype finding and
direction for further work; the generated drafts are not accepted minutes.
This is the Product Owner's account of what the prototype does, what was
measured, and what still limits an architecture decision. The accepted
[design](sprint_2_design.md), [functional test record](sprint_2_tests.md),
[ASR benchmark](ami_asr_benchmark.md), and
[staged-minutes trial](tests/multistage_minutes_trial_20261004.md) contain
the corresponding criteria and evidence. Model weights and approved
natural audio remain outside Git.

## How the Product Owner can validate this increment

For the presentation, use the [single-command live demo](demo/README.md).
Slide 10 and stage 4 demonstrate speaker naming through `recognize name`,
show the saved map, explain its whole-cluster scope, and give the exact
command to reopen Meeting Review after the edit. The
[focused CLI check](tests/speaker_naming_demo_20261004.md) passed on a copy
of the real Sejm record; a verified identity still requires source listening.
The corrected slide and presenter script also give a standalone command
block for the currently open Sejm record, including its actual UUID and
store, and a prompt to enter the name. The
[full-block test](tests/speaker_naming_copyable_command_20261004.json) passed
on a temporary copy without changing the active record.

Follow the [four-step real-model walkthrough](#product-owner-walkthrough--real-local-models)
to transcribe English and Polish, inspect poor-audio warning ranges, assign a
speaker name, and generate minutes. It gives runnable commands, human-readable
record views, observed results, and limitations. The [benchmark's Product
Owner summary](ami_asr_benchmark.md#summary-for-the-product-owner) and
[FR-11 comparison](ami_asr_benchmark.md#fr-11-bilingual-extension--pbi-0116-and-pbi-018)
add reference-based quality, runtime, footprint, and offline evidence. The
[test record](sprint_2_tests.md) states expected and observed gate outcomes
and links every raw log. The [SRS](../../docs/srs.md) defines the accepted
requirements; the [progress board](../../PROGRESS_BOARD.md) shows PBI status.

The [functional test record](sprint_2_tests.md#synthetic-cli-contract-check--test-only-reference-path)
contains the separate deterministic CLI and storage test.

The implementation is traceable from [CLI dispatch](../../Sources/MeetingCLI/main.swift)
through [configuration](../../Sources/MeetingCore/Configuration.swift),
[local ASR adapters](../../Sources/MeetingCore/ProcessTranscribers.swift),
and the [stored record](../../Sources/MeetingCore/Record.swift). The
[FLEURS fetcher](../../experiments/fetch_fleurs_subset.py) and
[benchmark runner](../../experiments/benchmark_fleurs.py) reproduce the
language experiment; the [fixture generator](../../tests/fixtures/README.md)
documents the invented meeting. These links are for traceability after
reading the result, not a substitute for its interpretation here.

## Prototype conclusion: what the minutes experiment teaches us

The one-call, quote-only minutes design failed as a way to produce usable
minutes from natural meetings. On the same saved 120-second AMI transcript,
the 30B model produced one source-exact excerpt of the product brief after a
repair, but no topic-level account of the discussion. On the saved Polish
Sejm transcript it repeated malformed JSON and saved no minutes. Those
failures remain visible in the [controlled 30B trial](tests/qwen3_30b_minutes_trial_20261003.md);
they prompted the accepted multi-stage design rather than being erased from
the project history.

The new candidate separates immutable ASR text, a reversible reading view,
topic discovery, full utterance-to-topic assignment, per-topic summaries,
item extraction, and source validation. The final recorded English AMI run
retained all 217 raw segments, formed 21 reading utterances, assigned all
21 to five proposed topics, and saved five source-linked prose summaries.
It took 24.981 seconds and reached 16.01 GB maximum child-process resident
memory on this Mac. The [saved AMI draft](tests/multistage_20261004/ami/record.json)
demonstrates **coverage and readable draft structure**, but only **2/5**
summaries passed a strict manual check that every material claim follows
from its own cited utterances. One topic calls room-equipment setup
remote-control functionality; another turns the ASR phrase “PowerPoint
reservation” into making a presentation. An earlier staged AMI candidate
also proposed four unsupported decision/action items, which were withheld.
The [controlled trial report](tests/multistage_minutes_trial_20261004.md)
separates that historical attempt from the final run.

The final Polish Sejm run retained all 801 raw segments, formed 32 reading
utterances, assigned all 32 to four topics, and saved four prose summaries
and one candidate budget-opinion decision. It took 53.410 seconds and
reached 17.34 GB maximum child-process resident memory on this Mac,
compared with the earlier same-transcript one-call 30B run, which saved no
minutes. These structural and runtime measurements come from the
[Sejm run metrics](tests/multistage_20261004/sejm/metrics.json) and
[saved draft](tests/multistage_20261004/sejm/record.json). Only **2/4**
summaries passed the same strict manual citation audit: one budget number
omits the cited source's next utterance containing its unit, and the PKN
summary adds claims not supported by its sole cited utterance. The
candidate decision is cited and assigned to the opinion-and-transition
topic, but it misses the separate prior-protocol acceptance in the saved
excerpt. This is an inspectable Polish draft, not dependable meeting
minutes. Earlier staged candidates, including one that named the wrong
committee and linked the decision to another topic, remain preserved in
the trial evidence.

The room-equipment/product confusion is a **topic-meaning error**. It came
from grouping and naming utterances about plugging in and operating a
device in the room, while the later project brief discusses designing a
remote control. The saved source words and topic assignments show this;
changing speaker labels alone would not resolve the ambiguity. The model
also repeatedly called meeting logistics and budget amounts decisions or
tasks. Conservative type gates now withhold candidates whose cited words
do not explicitly support the proposed type. These gates protect the saved
draft, but they can miss a real item phrased without a recognized signal,
so their recall needs separate measurement.

Technical response quality is a separate risk. The model generated too
many narrow topics, malformed or trailing-punctuation JSON, an extraction
array instead of the requested wrapper, overlong or incomplete citations,
and inconsistent topic assignments across calls. The implementation
validates each stage, asks for at most two repairs, allows only narrowly
defined structural normalization, and keeps the previous record if any
stage still fails. Passing these checks proves that IDs, schema, segment
accounting, and cited excerpts are technically valid; it does not prove
that a paraphrase is entailed by the recording.

Operator transcript review is therefore part of the product path, not
merely a test activity. The review player can replay a source range and
shows the segment ID. `transcribe correct` requires the operator to confirm
audio review before adding a text correction to a separate, reversible
layer. The raw ASR words remain unchanged; the corrected reading is used
by the multi-stage candidate, and existing minutes are invalidated until
regenerated. The real-model AMI and Sejm runs did not include operator word
corrections, so they measure the model on the saved ASR transcript, not on
an edited reference. Audio-backed review is especially relevant to short
unassigned Polish fragments, numbers, names, and speaker continuity; a
structural cleanup proposal alone does not establish what the recording
actually says.

The architecture decision from this prototype is to keep deterministic
segment preservation and source gates around a replaceable local minutes
model, to evaluate topic correctness and claim support against human
references, and to provide audio-backed operator corrections before
participant use. The staged pipeline is a useful direction because it
preserved the raw transcript, covered every reading utterance with a topic,
and produced inspectable drafts where the one-call approach often produced
none. It has not solved semantic accuracy: only 2/5 AMI and 2/4 Sejm topic
summaries passed the strict source-support audit. The next increment must
test topic boundaries, claim-level support, decision and task recall, and
the effect of operator corrections on actual meeting audio. Passing schema,
citation, and unit checks cannot substitute for these evaluations. This is
the Sprint 2 prototype conclusion, not acceptance of the generated minutes
or an assertion that the sprint handover has occurred.

## Implementation and design compliance

The Swift package has a portable MeetingCore library, a meeting-summarizer CLI, and a SwiftUI MeetingReview app. MeetingCore owns validated source ranges, transcript segments, neutral speaker labels, chair corrections, source-linked review items, processing provenance, quality warnings, and atomic local JSON storage. It does not import SwiftUI or AppKit. The CLI and review player load the same persisted record, so neither has a second business-data format. Local model executables are configured by path and run as separate processes. There is no remote inference fallback.

The accepted CLI amendment gives three independent operations. Transcribe creates a transcript-only record. Recognize is optional: the local FluidAudio diarizer assigns anonymous labels, while recognize name and recognize move let a chair correct the record. Summarize is optional and works with neutral or absent speaker labels. It invokes a local MLX language model, validates its structured output and source IDs, and saves minutes to the same record. The older import command remains for compatibility with the first prototype tests.

The Product Owner confirmed on 2026-10-03 that transcription should be
treated as a simple ordered sequence of timed text. That is the implemented path:
FluidAudio returns text and, when available, word times; whisper.cpp
returns text and time offsets. The Swift adapters convert either result
into validated `TranscriptSegment` values with start time, end time, and text. MeetingCore
then writes the local meeting-record JSON. The engines' JSON files are
temporary machine transport, not text prompts asking ASR to construct a
meeting record. A reader can see the transcript as timed lines, for
example `00:04.72–00:05.14  Hello`, while the saved JSON retains exact
numeric offsets for seeking and later speaker correction. The CLI currently
prints the record UUID; the documented `jq` views show its timed segments.
This prototype does not stream captions live to stdout.
No transcription model receives the long minutes prompt reproduced later
in this implementation record.

PBI-011.1, core and store: the record contract and atomic store are implemented. IT-1 starts the CLI in a separate process and reloads its output through MeetingStore. The child passed its six prescribed gates and was committed as 72fb8d4.

PBI-011.2, CLI: transcribe, recognize, recognize name, recognize move, and summarize are implemented and return the same record UUID across later steps. Invalid media, unknown IDs, missing configured models, and invalid corrections produce explicit errors. A synthetic three-command flow and a real FluidAudio transcription have run. Its six prescribed gates passed after help was corrected to mention the compatible import route; the audited completion commit is 5c5a7bf.

PBI-011.3, fixture and corrections: the checked-in invented 16 kHz mono WAV and paired reference JSON contain five timed turns from two speakers, a decision, an action, and an open question. The fixture generator was rerun outside the checkout; it produced 16.727125 seconds of audio with valid ranges and references. A fresh regeneration for this child again produced 16 kHz, one channel, 16-bit PCM, 16.727 seconds, and five reference turns. The chair named speaker_2 Ada and moved turn_1 to that label in a saved record. The synthetic summary then produced four review items. All six child gates passed; the audited completion commit is 1bae555.

PBI-011.4, review player: the SwiftUI app built and opened the real AMI record by ID. It displayed the transcript and 16 quality warnings; selecting the first warning sought the local audio to 19.3 seconds, and selecting a transcript turn sought to 4.7 seconds. The first AVKit VideoPlayer version crashed, so audio playback was changed to AVFoundation. A continuous-playback check was disruptive; the current version pauses after the selected source range and builds. That bounded playback has not been manually replayed since the user closed the app, and the app was not reopened for this child gate. The accepted build, manual open/seek, and CLI-created record integration criteria passed, as did all six child gates. The audited completion commit is aafa38e.

PBI-011.5, local-model integration: FluidAudio 0.17.4 with Parakeet TDT 0.6B v2, whisper.cpp with Whisper base.en, the FluidAudio offline diarizer, and MLX Swift LM 3.31.3 with locally staged Qwen3-4B-Instruct-2507 4-bit weights have all executed locally. The Fluid and whisper adapters each saved a timed synthetic transcript. Fluid transcribed the full approved AMI headset recording, and the diarizer saved labels and 16 warnings to record 87A64680-FD3C-44D4-9529-039E7071E46A. Xcode 27 with Metal Toolchain built MLX Swift's default.metallib. The MLX adapter generated and persisted source-linked minutes from the invented fixture in record 8DAAA0BB-C4A0-4863-9198-025E9FD4E643. On a natural 120-second AMI excerpt, the first word-level prompt produced truncated JSON. Source chunks made the response parseable; citations expand to original transcript IDs and an unsupported model owner is discarded. Record 4604E907-2EE9-4FE6-974A-8D22A5F9914D now contains the natural-audio minutes experiment. Its content quality failed, as explained below. The pinned adapter build, model artifact hash, local-only inference, transcript/source evidence, and all six child gates passed; the audited completion commit is b70ef21.

PBI-018, benchmark technical decisions: [the decision-facing report](ami_asr_benchmark.md) includes same-input accuracy, affected-speaker errors, alternate lapel input, repeated wall time, process resident memory, model footprint, timestamp diagnostics, diarization coverage, warning coverage and spillover, disconnected-network inference, and the MLX minutes experiment. On the common headset input, FluidAudio had 19.48% WER against 28.79% for whisper.cpp. Its affected-speaker reference-linked error rate was 27.78% against 58.55%. Three 120-second runs gave median wall times of 0.73 and 1.29 seconds. The diarizer found three clusters for four reference people and merged the low-quality participant with another speaker. The stored 16 warnings are therefore useful review cues, not reliable participant identification. The natural-audio MLX minutes converted a project goal into a decision, invented two actions, and generated two questions that were not asked. This is an observed quality failure, not a recommendation to use those minutes. The benchmark scoring was reproduced from stored outputs and all six PBI-018 gates passed. Sprint 3 will analyze the measurements and select architecture changes.

PBI-011.6, bilingual transcription: `transcribe` now accepts
`--language en|pl|auto`, with `en` as the existing-command default. It saves
`requestedLanguage` with backend and model revision. `fluidModelVersion` in
settings selects Parakeet v2 or v3; `v2` rejects `pl` and `auto`. The
multilingual Whisper model accepts `pl` and `auto`, while `.en` model paths
are rejected for them. The Fluid helper loads v3 and passes the available
language hint. `whisperUseGPU: false` requests CPU execution after the
multilingual model's Metal initialization failed on this Mac. On five pinned
natural clips per language, v3 WER was 11.49% English and 3.41% Polish;
Whisper base WER was 18.39% and 27.27%. These read-speech measurements and
their limits are fully interpreted in the benchmark. Mixed-language `auto`
omitted the English half of an exploratory splice for both engines.

## Build, test, and environment

The root package builds with swift build. Swift Testing 6.3.2 is pinned for the test targets; swift test currently passes 18 tests across core and integration suites. The accepted RUP runner uses smoke, unit, and integration levels, both new-only and regression. The main wrapper, tests/run-sprint-gates.sh, runs all six levels once and saves separate timestamped logs. Every Sprint 2 child, PBI-018, and the PBI-011 parent passed separate six-gate runs; results and failed-attempt explanations are in [the test record](sprint_2_tests.md).

The normal package does not download model weights. The FluidAudio helper, whisper.cpp executable and model, MLX Swift adapter and Qwen model are staged separately. Model setup may require network access once; meeting inference uses local paths. The tested Mac now has Xcode 27 and the Metal Toolchain. Xcode reports the Metal component installed and its compiler runs directly, although xcrun metal still reports a missing component. The MLX Swift library was built by xcodebuild; its generated default.metallib was copied beside the adapter executable as mlx.metallib. That manual packaging step remains a portability risk.

The MLX Swift LM package is pinned to 3.31.3 and its MLX Swift dependency to 0.31.6 in experiments/MinutesAdapter/Package.resolved. The staged Qwen model is revision 50d427756c6b1b2fe0c0a10f67fbda1fc8e82c1b under /private/tmp/meeting-minutes-models/qwen3-4b-instruct-2507-4bit. Its 2,263,022,417-byte model.safetensors has SHA-256 2a73c6c248601ab904e035548abd8e6abb65ea27dcb5f342fb0a8910eb44173f. The following build commands ran on this Mac after the model and package dependencies were staged:

~~~bash
swift build --package-path experiments/MinutesAdapter -c release
(cd experiments/MinutesAdapter/.build/checkouts/mlx-swift && xcodebuild build -scheme MLX -destination 'platform=macOS' -skipPackageUpdates -derivedDataPath /private/tmp/meeting-mlx-derived)
cp /private/tmp/meeting-mlx-derived/Build/Products/Debug/mlx-swift_Cmlx.bundle/Contents/Resources/default.metallib experiments/MinutesAdapter/.build/out/Products/Release/mlx.metallib
~~~

The copied resource is a local build artifact, not checked into Git. This Xcode 27 build places the adapter at experiments/MinutesAdapter/.build/out/Products/Release/meeting-mlx-minutes. A prior Command Line Tools build used a different .build path. Set mlxExecutable to the executable's actual absolute path and mlxModelDirectory to the staged Qwen directory in the settings JSON. A process-level network-denial run of that executable generated valid structured synthetic minutes using only the staged local model. The natural AMI result is a quality failure even though local execution succeeded.

On 2026-10-03 the larger Qwen3-30B-A3B-Instruct-2507 MLX 4-bit candidate
was downloaded to the persistent, Git-ignored
`/Users/rstyczynski/projects/meeting_minutes/.models/qwen3-30b-a3b-instruct-2507-4bit/`
directory. All
16 files are present, and the four weight shards match the pinned
revision's exact byte counts and SHA-256 hashes in the [download
evidence](tests/qwen3_30b_download_20261003.md). The controlled
[30B trial](tests/qwen3_30b_minutes_trial_20261003.md) then used a separate
settings file and clean copies of the same saved AMI and Sejm transcripts.
It retained per-attempt raw responses through the opt-in
`MEETING_MINUTES_DIAGNOSTICS_DIR` environment variable. AMI saved one
source-exact brief quotation after citation repair. Sejm returned the
same malformed JSON three times and saved no items. The trial records
the source review, timing, memory, and preserved transcript. The
walkthrough settings and product default still point to the 4B model;
the 30B candidate did not meet the minutes-quality bar. After a clean
Swift build, `mlx.metallib` had to be copied again from the compiled
`mlx-swift_Cmlx.bundle` resource beside the release adapter. The
diagnostic variable is for local evidence capture, not a user-facing
minutes feature.

For FR-11, stage a multilingual model before use. The tested Fluid assets
are under `/private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v3` and
the release helper is
`experiments/FluidAdapter/.build/release/meeting-fluid-asr`. The tested
multilingual Whisper weight is
`/private/tmp/meeting-minutes-whisper.cpp/models/ggml-base.bin` and its
executable is `/private/tmp/meeting-minutes-whisper.cpp/build/bin/whisper-cli`.
The [benchmark](ami_asr_benchmark.md) records artifact checksums, licenses,
the FLEURS references, all scores, and offline behavior. The source and
scoring scripts are [fetch_fleurs_subset.py](../../experiments/fetch_fleurs_subset.py)
and [benchmark_fleurs.py](../../experiments/benchmark_fleurs.py).

## Product Owner walkthrough — real local models

The current handover uses the [single-command live demo and presenter
script](demo/README.md). It builds its own settings, starts with a fresh
store, pauses for operator review, and distinguishes fresh model output
from the earlier successful 30B trial. A [4 October rehearsal](tests/po_demo_rehearsal_20261004.md)
ran all noninteractive CLI stages: 2576 English and 802 Polish segments,
then quality-gate rejection of both fresh 30B minutes responses with both
transcripts retained. The older command sequence below documents the
individual 4B experiments and their historical output; use the new demo
script for the Product Owner session.

Run these commands from the repository root in one Terminal session on the
Sprint 2 Mac. They use real local models and public, natural audio; they do
not inject answers. The AMI English meeting has a documented weak headset.
The Polish source is a ten-minute excerpt of an actual Sejm committee
meeting with multiple speakers. The AMI and Sejm audio, model weights, and
generated records live under `/private/tmp`, outside Git. The [AMI fixture
record](ami_es2002a_fixture.md) and [Polish meeting source
record](polish_sejm_meeting_fixture.md) give provenance. The
[benchmark](ami_asr_benchmark.md) gives reference-based English and separate
single-speaker language scores; a defensible whole-clip Polish meeting WER
is not yet available. Xcode and Metal Toolchain are needed for the optional
MLX minutes step. The corrected meeting walkthrough ran on this Mac on
2026-10-02.

The following preflight shows the concrete files used below. On this Sprint
2 Mac they are already staged. If any path is missing, stage the AMI mix from
its [approved source](ami_es2002a_fixture.md), stage the Polish meeting from
the [official source](polish_sejm_meeting_fixture.md), and use the Fluid
helper's `--download-models` and `--download-diarizer-models` commands before
continuing. The MLX Qwen model and compiled `mlx.metallib` were staged
separately as described in [Build, test, and environment](#build-test-and-environment);
they are not installed by the normal package build. This is a packaging gap
for a fresh Mac.

~~~bash
ls -lh /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Mix-Headset.wav /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Headset.120s.wav /private/tmp/meeting-polish-gor-20241016-10min.wav
ls -ld /private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v2 /private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v3 /private/tmp/meeting-minutes-models/offline-diarizer/speaker-diarization /private/tmp/meeting-minutes-models/qwen3-4b-instruct-2507-4bit
ls -l experiments/FluidAdapter/.build/release/meeting-fluid-asr experiments/MinutesAdapter/.build/out/Products/Release/meeting-mlx-minutes experiments/MinutesAdapter/.build/out/Products/Release/mlx.metallib
~~~

Create settings for the English AMI and Polish Sejm meetings, speaker labeling,
and minutes. These are real executable and model paths on this Mac. The
English AMI run selects the Parakeet v2 model used for the AMI benchmark;
Polish selects multilingual Parakeet v3. Keep the same `store_dir` and shell
session for all steps.

~~~bash
project_root="$(pwd)"
store_dir=/private/tmp/meeting-owner-demo
mkdir -p "$store_dir"
cat > /private/tmp/meeting-owner-english-settings.json <<JSON
{"transcriber":"fluid","fluidModelDirectory":"/private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v2","fluidModelVersion":"v2","fluidExecutable":"$project_root/experiments/FluidAdapter/.build/release/meeting-fluid-asr","fluidDiarizerModelDirectory":"/private/tmp/meeting-minutes-models/offline-diarizer/speaker-diarization","fluidDiarizerExecutable":"$project_root/experiments/FluidAdapter/.build/release/meeting-fluid-asr","mlxModelDirectory":"/private/tmp/meeting-minutes-models/qwen3-4b-instruct-2507-4bit","mlxExecutable":"$project_root/experiments/MinutesAdapter/.build/out/Products/Release/meeting-mlx-minutes"}
JSON
cat > /private/tmp/meeting-owner-polish-settings.json <<JSON
{"transcriber":"fluid","fluidModelDirectory":"/private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v3","fluidModelVersion":"v3","fluidExecutable":"$project_root/experiments/FluidAdapter/.build/release/meeting-fluid-asr","fluidDiarizerModelDirectory":"/private/tmp/meeting-minutes-models/offline-diarizer/speaker-diarization","fluidDiarizerExecutable":"$project_root/experiments/FluidAdapter/.build/release/meeting-fluid-asr","mlxModelDirectory":"/private/tmp/meeting-minutes-models/qwen3-4b-instruct-2507-4bit","mlxExecutable":"$project_root/experiments/MinutesAdapter/.build/out/Products/Release/meeting-mlx-minutes"}
JSON
jq -e . /private/tmp/meeting-owner-english-settings.json /private/tmp/meeting-owner-polish-settings.json
~~~

### 1. Transcribe English and Polish

The first command transcribes the full AMI headset mix. The second
transcribes the Polish committee excerpt. Each prints a new record UUID to stdout;
SwiftPM may print build warnings to stderr. The `jq` views read the saved
records, so the Product Owner can inspect output without opening raw logs.

~~~bash
english_id="$(swift run meeting-summarizer transcribe /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Mix-Headset.wav --transcriber fluid --language en --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir")"
polish_id="$(swift run meeting-summarizer transcribe /private/tmp/meeting-polish-gor-20241016-10min.wav --transcriber fluid --language pl --settings /private/tmp/meeting-owner-polish-settings.json --store "$store_dir")"
printf 'English record: %s\nPolish record: %s\n' "$english_id" "$polish_id"
cat "$store_dir/$english_id.json" | jq -r '"English: \(.segments|length) timed segments; model \(.modelRevision); requested \(.processingParameters.requestedLanguage)", ([.segments[:12][].text] | join(" "))'
cat "$store_dir/$polish_id.json" | jq -r '"Polish: \(.segments|length) timed segments; model \(.modelRevision); requested \(.processingParameters.requestedLanguage)", ([.segments[:120][].text] | join(" "))'
~~~

The verified runs saved 2,576 English timed segments with model
`parakeet-tdt-0.6b-v2` and 802 Polish meeting segments with
`parakeet-tdt-0.6b-v3`. The Polish output includes the chair discussing the
meeting's time limit and opening the Commission sitting. Its source is a real
multi-person meeting; the official PDF identifies the chair and other
speakers. The English transcript has recognition errors; compare it with
the [AMI benchmark](ami_asr_benchmark.md) rather than treating a nonempty
transcript as an accuracy pass. The Polish written record is edited and not
time aligned, so this run has no whole-clip WER. `--language auto` is available, but the
exploratory English-to-Polish splice lost its English portion.

To read the actual saved words rather than only the counts above, open the
[Sprint 2 meeting transcription files](tests/transcripts/README.md). They
include the full English AMI meeting, the 120-second AMI excerpt used for
minutes evaluation, and the ten-minute Polish Sejm excerpt, each with time
ranges and anonymous speaker labels. These are uncorrected ASR results;
the linked JSON retains the original segment-level evidence.

### 2. Inspect low-quality audio warnings and speaker labels

Run local diarization on both meeting records. It assigns anonymous IDs
and saves warning ranges in the same JSON. On AMI the first warning links
to source audio near 19.3 seconds. A warning is a review cue, not an
automatic repair.

~~~bash
swift run meeting-summarizer recognize "$english_id" --diarizer fluid --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
cat "$store_dir/$english_id.json" | jq -r '"Speaker IDs: \([.segments[].speakerID // "unknown"] | unique | join(", "))", "Warning ranges: \(.qualityWarnings|length)", (.qualityWarnings[:5][] | "  [\(.range.startSeconds|floor)-\(.range.endSeconds|floor)s] \(.speakerID // "unknown"): \(.reason)")'
swift run meeting-summarizer recognize "$polish_id" --diarizer fluid --settings /private/tmp/meeting-owner-polish-settings.json --store "$store_dir"
cat "$store_dir/$polish_id.json" | jq -r '"Polish speaker IDs: \([.segments[].speakerID // empty] | unique | join(", "))", "Polish warning ranges: \(.qualityWarnings|length)"'
~~~

The verified run produced `S1`, `S2`, and `S3` and 16 low-speech-level
warnings for `S3`. The first begins at 19.32 seconds. AMI has four
annotated participants; this diarizer merged the weak-headset participant
with another person. The warning catches much of the affected speech but
also includes another speaker. Do not assign a real person's name to `S3`
from this result alone. The [benchmark's speaker analysis](ami_asr_benchmark.md#speaker-attribution-experiment)
quantifies the merge and warning spillover.

The Polish meeting run produced S1, S2, and S3 and zero weak-audio warnings.
The official sitting record names the chair, a minister, and a later
presenter; their turns align broadly with the three cluster starts at 108,
222, and 582 seconds. This is evidence of multiple voices and a functioning
labeling path, not a scored diarization-accuracy result.

The optional [review player](../../Sources/MeetingReview/main.swift) can
open this saved record by UUID and let the chair select a warning or
transcript range to hear the original local audio. Playback starts only
when a row is selected. It was manually opened and sought to the 19.3-second
warning earlier in the sprint; bounded playback after the latest player
change has not been manually replayed.

### 3. Assign a name after listening

`recognize name` stores a chair-entered name for an existing anonymous ID.
The following label is deliberately a demonstration, not the identity of
an AMI participant. Replace it with a verified name when reviewing a real
meeting. The command persists the mapping in the same record. `recognize
move` can correct a transcript segment assigned to the wrong speaker.
For the Polish record, the official sitting record supports identifying
the chair on the opening S1 turn. It does not verify every segment in S1.
The Product Owner handover therefore keeps that entire cluster anonymous.

~~~bash
swift run meeting-summarizer recognize name "$english_id" S2 'Ada (demonstration alias)' --store "$store_dir"
cat "$store_dir/$english_id.json" | jq -r '"Speaker names:", (.speakerNames | to_entries[] | "  \(.key) = \(.value)")'
cat "$store_dir/$polish_id.json" | jq -r '"Polish named speakers: \(.speakerNames|length)"'
~~~

The demonstration alias was saved on AMI; the Polish meeting retains neutral
speaker IDs. An earlier rehearsal assigned `S1 = Ryszard Petru` to the Sejm
record based on the official opening turn, but that applied the name to
unverified S1 segments too and is not part of this handover sequence.
The alias is not carried into the separate minutes input. Neither command
automatically identifies anyone by voice. The [SRS](../../docs/srs.md)
records automatic identity suggestions as a later capability, not this
prototype's current result.

### 4. Generate and inspect minutes

This step uses the 120-second AMI excerpt because it is the natural-audio
sample on which the local MLX minutes adapter was exercised. It makes a new
record, labels speakers, keeps names neutral, and runs the local Qwen model.
`summarize` is optional; it can also run without `recognize`. The approved
response gate now rejects malformed, unsupported, or uncited output after
two repair attempts, preserving the transcript and saving no draft minutes.
That is the expected outcome of the current 4B experiment, rather than a
successful minutes demonstration. The full 20-minute meeting has not been
validated for minutes quality.

~~~bash
short_id="$(swift run meeting-summarizer transcribe /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Headset.120s.wav --transcriber fluid --language en --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir")"
swift run meeting-summarizer recognize "$short_id" --diarizer fluid --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
swift run meeting-summarizer summarize "$short_id" --summarizer mlx --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
cat "$store_dir/$short_id.json" | jq -r '"Transcript retained: \(.segments|length) segments", "Draft items: \(.reviewItems|length)", "Minutes source: \(.processingParameters.minutesSource // "none")"'
~~~

The current 4B trial returned a validation error and retained the saved
transcript with zero draft items. In the earlier `minutes-v2` no-name
rehearsal, the model saved three review items with
`minutesSource: local-model`: a summary and two open questions. One question
expands the source's “this thing” to a remote-control system without support
from its cited 14.8–16.8 second range; the second adds an inferred reference
to a previous task. The summary has no source IDs. This is a
**content-quality failure** despite successful local inference. An earlier
named rehearsal saved six items and repeated the invented Ada alias; that
output is historical evidence of why demonstration aliases must not be fed
into minutes. The
[benchmark's minutes analysis](ami_asr_benchmark.md) explains the earlier
natural-audio failure and why Sprint 3 must revisit the model and prompt
before meeting minutes can be trusted.

The initial `summarize` attempt on the ten-minute Polish Sejm record failed:
the model cited speaker label `S1` as if it were a source segment ID. The
strict validator rejected it and saved no minutes. The MLX adapter now
separates `SOURCE_ID` from `SPEAKER` in its prompt and makes at most two
technical repair attempts. The core also omits an action owner unless that
speaker appears in the item's cited segments. A historical `minutes-v2`
rerun exited 0 and saved four draft items; the active evidence-first gate
rejects the 4B candidate's incompletely cited decision quote. Run this
command after the preceding steps to observe the current result:

~~~bash
swift run meeting-summarizer summarize "$polish_id" --summarizer mlx --settings /private/tmp/meeting-owner-polish-settings.json --store "$store_dir"
jq -r '"Polish transcript: \(.segments|length) segments", "Polish draft items: \(.reviewItems|length)"' "$store_dir/$polish_id.json"
~~~

The earlier draft's decision that the commission positively opined on the budget section is
supported by the cited 540–546 second turn. The action incorrectly treats a
request to present the next budget as a future task, and the open question
was not asked in its cited 380–387 second source range. The summary has no
source citations. Thus the structural error is fixed, but the generated
minutes still fail content review and must not be published. This is a
blocking quality issue for the Product Owner's delivery decision.

The [Polish fixture record](polish_sejm_meeting_fixture.md) and
[functional test record](sprint_2_tests.md#polish-multi-person-meeting-correction--2026-10-02)
retain the source and failure evidence.

### Longer English meeting input

The structural repair and the still-open content and long-input minutes
defects are registered in [Sprint 2 bugs](sprint_2_bugs.md). Passing CLI or
gate runs does not close the two open defects.

The Product Owner requested a longer English public meeting comparable to
the Sejm source. A 30-minute excerpt of the [U.S. Department of Energy
ITIAC Day 2 meeting](doe_itiac_day2_fixture.md) is staged at
`/private/tmp/meeting-doe-itiac-day2-30min.wav`. Its official page has a
speaker-labeled transcript; the audio and transcript are not bundled in
Git. The direct CLI `transcribe` command used `--language en`, the existing
English settings, and store `/private/tmp/meeting-doe-itiac-sprint2`.
It created record `36237678-66EB-456D-897A-4687BF33F390` with 4,216
timed Parakeet v2 segments. A direct `recognize --diarizer fluid` on that
record saved eight anonymous IDs. The first S1, S3, and S5 turns align
with named speakers in the official transcript. This does not establish
whole-cluster attribution accuracy. The following view ran on the saved
record:

~~~bash
jq -r '"DOE English: \(.segments|length) timed segments; model \(.modelRevision)", "Speaker IDs: \([.segments[].speakerID // empty]|unique|join(", "))", "Warning ranges: \(.qualityWarnings|length)", "Review items: \(.reviewItems|length)"' /private/tmp/meeting-doe-itiac-sprint2/36237678-66EB-456D-897A-4687BF33F390.json
~~~

It prints 4,216 segments, eight IDs `S1` through `S8`, zero weak-audio
warnings, and zero review items. A local Qwen3-4B MLX `summarize` attempt
on the entire 30 minutes returned status 2 because the model response
could not be parsed. A separate, identical saved transcript with staged
Qwen2.5-7B also returned status 2 on structured output. Both records
preserved the transcript and labels. The [test record](sprint_2_tests.md#doe-30-minute-english-meeting-and-second-minutes-model--2026-10-02)
and [benchmark](ami_asr_benchmark.md#polish-meeting-minutes-quality-check)
give the source, exact errors, comparison basis, and limits.

### Other delivered prototype behavior

The CLI saves timed transcripts, model and language provenance, anonymous
speaker IDs, chair-assigned names, segment corrections, quality-warning
ranges, and cited review items in local JSON. `transcribe`, `recognize`, and
`summarize` are separate commands; the latter two are optional. The review
player reads the same record and can seek to transcript, warning, and source
ranges. FluidAudio and whisper.cpp ASR adapters are configurable. The staged
models ran without network access during inference. The prototype does not
yet provide reliable speaker identity, automatic audio repair, dependable
natural-meeting minutes, or verified mixed-language switching. The
[functional test record](sprint_2_tests.md) contains the synthetic CLI
contract checks and the six-gate regression evidence.

A missing local WAV gives a clear error and does not create a record:

~~~bash
swift run meeting-summarizer transcribe tests/fixtures/no-such-meeting.wav --transcriber fluid --store "$store_dir"
printf 'status=%s\n' "$?"
~~~

This verified command printed `Media file does not exist` to stderr and
returned status 2. SwiftPM may print build progress first.

## Remaining limitations and next checks

The synthetic fixture proves contracts and corrections, not ASR or LLM accuracy. The AMI benchmark covers one English meeting and selected model sizes on one Mac. FR-11 adds a small paired read-speech check. A later real Polish Sejm excerpt has an official PDF reference: its [passage-level comparison](tests/polish_sejm_pdf_transcription_review_20261002.md) finds recognizable turns and decision content, with word, name, acronym, and numeric-unit errors. It does not provide a whole-excerpt WER or verified speaker IDs. The `auto` setting is unsuitable for an in-recording language switch in the exploratory check, and the multilingual Whisper Metal path failed on this host. Speaker labels are anonymous and the poor-headset speaker was merged with another person. Warnings identify ranges for review but cannot yet reliably name the affected person. The natural-audio minutes fail content quality despite valid JSON and source links; no automatic publication should rely on them. The review player's bounded playback change and MLX model packaging need later checks. The six prescribed gates passed for each child and benchmark increment and the reopened PBI-011 parent; architecture interpretation belongs to Sprint 3. No remote push has been made.

## Model prompt ledger and response gate — 2026-10-02

The response gate applies these checks in order before a minutes result can
reach another product step:

1. **Input bound.** The saved transcript must be nonempty and no longer
   than the prototype's 600-second minutes limit. The model is not called
   when this check fails.
2. **Technical response shape.** The model text must be a complete JSON
   object with a cited summary object, arrays for decisions/actions/open
   questions, nonempty text, and one or two source IDs per item. Item counts
   are bounded. Malformed or oversized responses are not saved.
3. **Source integrity.** Each ID must exist in the model-facing transcript,
   and each quotation must appear exactly in its cited chunks. After chunk
   expansion, the core checks persisted segment IDs and time ranges again.
4. **Meaning and identity.** Conservative rules reject a purported
   decision without explicit agreement language, an action without a future
   commitment, or a question absent from its cited words. An owner is
   retained only when its speaker ID occurs in the cited segments. These
   rules are safeguards, not proof that the transcript is correct.
5. **Failure boundary.** A technical error gets at most two specific
   repair prompts and full revalidation. Remaining errors leave the last
   valid local record intact. Unsupported content is withheld from
   `reviewItems` and counted for the operator; it cannot silently feed a
   later product stage.

The first four checks are implemented for Sprint 2 minutes. NFR-06 in the
[SRS](../../docs/srs.md#nfr-06--validate-model-responses-before-downstream-use)
sets the same boundary for future model-backed capabilities. Human audio
review is still required before a draft becomes participant-facing minutes.

The local minutes experiments use `ChatSession` with the staged Qwen model
and `temperature: 0`. The earlier single-call pipeline uses `maxTokens:
1024`; the current staged pipeline uses 512 for topics, 768 for item
extraction, and 1536 for assignment and topic-summary calls. Temperature
zero reduces sampling variation but does not make a model's words or schema
dependable. FluidAudio ASR, whisper.cpp ASR, and Fluid diarization receive
configuration and language hints, not free-text prompts. The MLX minutes
adapter is the only product path in this sprint that sends free-text
instructions. The prompt templates below show every current stage and the
older single-call versions retained for comparison.

### Current staged minutes prompts (`minutes-v4.1-multistage`)

The topics stage receives the following exact system instruction. Its first
user message is one line per cleaned utterance in the form `utt_ID | speaker
name or ID or Unknown | start-end s | text`, with actual values and no angle
brackets. The speaker and time text is context, not evidence of correctness.

~~~text
Identify distinct substantive meeting topics from timed utterances.
Return 2 to 5 broad topics for the whole excerpt. Merge closely
related points. Do not list individual features, roles, names,
sentences, or synonyms as separate topics. Stop after t5.
Output only {"topics":[{"id":"t1","title":"short title",
"source_utterance_ids":["utt_1"]}]}. Use t1,t2,... in order.
Cite at least one exact utterance ID for every topic. Include real
procedural topics when discussed; do not invent a catch-all topic.
Keep titles short. Do not infer unsupported facts.
~~~

Assignment calls send at most 24 lines of `utt_ID | text`. Their system
instruction is below; `<topic list>` is replaced by each actual `tN: title`
line produced by the validated topics stage.

~~~text
Assign EVERY utterance to one or more substantive topics.
Return only {"assignments":[{"utteranceID":"utt_1",
"topicIDs":["t1"]}]}. Output each supplied utterance once.
Never use a topic or utterance ID outside the supplied lists.
Do not assign solely by speaker; use the spoken content.
Topics:
<topic list>
~~~

For each validated topic, a separate summary call sends only its assigned
`utt_ID | text` lines and substitutes that topic's title for `<title>`.

~~~text
Summarize the topic “<title>” in one or two clear sentences.
Paraphrase; do not present a quotation as the summary. Output only
{"text":"factual topic summary","source_utterance_ids":["utt_1"],
"evidence_quote":"exact contiguous words from cited utterance"}.
Keep evidence_quote to 8–30 words and under 250 characters.
Cite utterance IDs from this topic. The evidence_quote must be
verbatim and support the summary. Omit unsupported detail.
~~~

For each topic with utterances containing an explicit item signal, an item
call sends those `utt_ID | text` lines and substitutes its title for
`<title>`. The signal filter is conservative and can miss a real item.

~~~text
Extract only explicit decisions, future commitments, tasks from
commitments, and still-open questions for topic “<title>”.
An agenda item, request to speak, or proposal is not a decision.
A budget amount being reported is not a committee decision.
A task requires a cited future commitment. Omit uncertainty.
Return at most three items total. Do not enumerate budget lines.
Return only {"items":[{"kind":"decision|action|task|openQuestion",
"text":"brief factual statement","source_utterance_ids":["utt_1"],
"evidence_quote":"exact contiguous source words",
"owner_speaker_id":null,"due_date":null}]}.
Keep each evidence_quote to 8–30 words and under 250 characters.
Use [] when no qualifying item exists. Owner and due date may be
non-null only when the cited words explicitly support them.
Never invent a person, date, item, or source ID.
~~~

Every stage checks JSON and stage-specific IDs, coverage, quotes, and type
signals. When a response fails, the same `ChatSession` receives this exact
repair message, with `<stage>` and `<validation error>` replaced. At most
two repairs are sent; every reply is fully revalidated.

~~~text
Your <stage> response failed validation: <validation error>.
Correct your previous answer using only the supplied transcript
and IDs. Follow the original JSON shape exactly. Output JSON only.
~~~

The adapter may reconcile an utterance cited by a proposed topic into its
separate assignment and may shorten a final-attempt quote only to a
substantial exact contiguous excerpt of the already cited utterance. The
adapter itself attaches the originating `topic_id` to extracted items. It
does not silently rewrite the substantive summary; a plausible but wrong
paraphrase can still pass. See the [accepted design](sprint_2_design.md#approved-multi-stage-minutes-repair-design--2026-10-03)
and the [stage implementation](../../experiments/MinutesAdapter/Sources/MeetingMLXMinutes/StagedPipeline.swift).

### Earlier single-call prompts, retained as failure evidence

For the legacy `minutes-v3-evidence` revision, the system instruction sent
to `ChatSession` is exactly:

~~~text
Select short, exact transcript quotations for a source-grounded draft.
Return one JSON object with keys summary (object), decisions (array),
actions (array), and open_questions (array). Every object must have
text (a verbatim contiguous quotation from the cited transcript)
and source_ids (one or two exact SOURCE_ID values). Never paraphrase.
A SPEAKER value such as S1 is never a SOURCE_ID. For example,
cite source_12 as ["source_12"], never ["S1"]. If a claim has no
exact source, omit the claim.
An action may have owner_speaker_id (canonical speaker ID, not a name) only
if the cited text explicitly states the owner. Use supplied speaker names
only where available. Do not invent facts, people, owners, dates, or source
IDs. Return at most one decision, one action, and one open question.
Keep every quotation short, ideally under 25 words. An introduction, an agenda,
a request for someone to speak, or a transition to the next topic is not
a decision or an action. A decision needs an explicit acceptance,
rejection, vote, or no-objection conclusion. An action needs an explicit
future commitment, not a request made during this meeting. Include an
open question only when a speaker actually asked it and it remained
unanswered; do not invent questions from agenda topics. If evidence is
absent or uncertain, return empty arrays. The summary must be a
short, verbatim quotation from one source chunk, with its source_id.
Do not explain or infer what the quotation means.
Use this exact JSON shape, replacing the example words and IDs:
{"summary":{"text":"exact quote","source_ids":["source_1"]},
"decisions":[{"text":"exact quote","source_ids":["source_2"]}],
"actions":[],"open_questions":[]}
Never put SOURCE_ID inside text. A quote spanning two source chunks
must cite both IDs in source_ids.
Return JSON only, without Markdown fences.
~~~

The first user message to the model is the complete bounded transcript.
Each model-facing chunk is a separate line using this exact format, with
actual values substituted from the saved record:

~~~text
SOURCE_ID=<source ID> | SPEAKER=<anonymous ID or anonymous ID / chair name> | TIME=<start>-<end>s | TEXT=<verbatim ASR words in this chunk>
~~~

The adapter groups up to 16 adjacent word segments from the same anonymous
speaker and at most eight seconds per chunk. A transcript with 40 or fewer
segments uses its persisted IDs directly. The active prototype rejects
minutes input longer than 600 seconds before sending this message.

After every response, the adapter checks complete JSON, object/array
shape, nonempty text, one or two existing source IDs, at most one candidate
of each type, and exact quotation containment in the cited chunks. If a
check fails, it sends this repair prompt, substituting the current Boolean,
invalid IDs, quote errors, and available IDs:

~~~text
Your previous response failed technical validation.
JSON/schema valid: <true or false>. Invalid source IDs:
<invalid IDs>. Quote/citation errors:
<errors>. Rewrite it as valid JSON
in this exact shape:
{"summary":{"text":"verbatim quote","source_ids":["source_1"]},
"decisions":[],"actions":[],"open_questions":[]}
Each array item must be an object with text and source_ids, never
a string. Put IDs in source_ids, never inside text. Cite every
source chunk needed for the full verbatim quote, using at most
two source_ids. Shorten a quotation if it spans more chunks.
Available IDs: <all model-facing source IDs>.
Omit unsupported items. Return only the JSON object.
~~~

The adapter sends at most two repair prompts. It validates each response
again; a third invalid response exits with a specific error and preserves
the prior meeting record. `MeetingCore` then independently expands
model-facing chunk IDs to persisted transcript IDs, checks quotation and
item-type support, and withholds unsupported candidates. A structurally
valid answer is therefore still not automatically a sound set of minutes.
The [response-gate tests](../../experiments/MinutesAdapter/Tests/MeetingMLXMinutesTests/ResponseValidationTests.swift)
use controlled malformed inputs, while the [real-model test record](sprint_2_tests.md)
reports how the two Qwen candidates behaved.

The earlier `minutes-v2` system instruction, used for the saved Sejm and
DOE experiments and some later AMI checks, was exactly:

~~~text
Produce meeting minutes from only the provided transcript. Return a JSON object
with keys summary (string), decisions (array), actions (array), and
open_questions (array). Each decision, action, and open question must have
text (string) and source_ids (array of exact SOURCE_ID values).
A SPEAKER value such as S1 is never a SOURCE_ID. For example,
cite source_12 as ["source_12"], never ["S1"]. If a claim has no
exact source, omit the claim.
An action may have owner_speaker_id (canonical speaker ID, not a name) only
if the cited text explicitly states the owner. Use supplied speaker names
only where available. Do not invent facts, people, owners, dates, or source
IDs. Cite at most three exact source IDs for each item. Return at most two
decisions, two actions, and two open questions. An introduction, an agenda,
a request for someone to speak, or a transition to the next topic is not
a decision or an action. A decision needs an explicit acceptance,
rejection, vote, or no-objection conclusion. An action needs an explicit
future commitment, not a request made during this meeting. Include an
open question only when a speaker actually asked it and it remained
unanswered; do not invent questions from agenda topics. If evidence is
absent or uncertain, return empty arrays. Keep the summary to two sentences.
Return JSON only, without Markdown fences.
~~~

Its first user message used the same `SOURCE_ID=... | SPEAKER=... |
TIME=... | TEXT=...` line format as v3. When a response cited an invalid
source ID, v2 sent this exact repair template with values substituted:

~~~text
Your JSON used invalid source_ids: <invalid IDs>.
Those are speaker labels or invented IDs, not SOURCE_ID values.
Rewrite the entire JSON using only these exact SOURCE_ID values:
<all model-facing source IDs>
Omit any decision, action, or question that cannot be supported
by one of those IDs. Keep the same JSON schema. Return JSON only.
~~~

The original `minutes-v1` prompt preceded source-chunk IDs. Its exact
system instruction was:

~~~text
Produce meeting minutes from only the provided transcript. Return a JSON object
with keys summary (string), decisions (array), actions (array), and
open_questions (array). Each decision, action, and open question must have
text (string) and source_ids (array of exact input segment IDs).
An action may have owner_speaker_id (canonical speaker ID, not a name) only
if the cited text explicitly states the owner. Use supplied speaker names
only where available. Do not invent facts, people, owners, dates, or source
IDs. Cite at most three exact source IDs for each item. Return at most two
decisions, two actions, and two open questions. An introduction, an agenda,
or a proposed goal is not a decision or an action. If evidence is absent,
return empty arrays. Keep the summary to two sentences.
Return JSON only, without Markdown fences.
~~~

Its first user message used one line per input segment in this exact
format, with values substituted:

~~~text
<segment ID> [<anonymous ID or anonymous ID / chair name>, <start>-<end>s]: <verbatim ASR words>
~~~

V1 had no repair prompt. No ASR or diarization text prompts were used.
These historical prompt templates explain the observed failures; they are
not the current product contract.
