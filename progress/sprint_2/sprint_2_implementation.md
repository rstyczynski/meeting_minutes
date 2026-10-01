# Sprint 2 — Implementation record

Status: implemented and tested for the Sprint 2 prototype scope. This is the Product Owner's account of what the executable prototype does, what was measured, and what still limits an architecture decision. The accepted [design](sprint_2_design.md), [functional test record](sprint_2_tests.md), and [AMI benchmark report](ami_asr_benchmark.md) contain the corresponding criteria and evidence. Model weights and the approved AMI recording remain outside Git.

## Implementation and design compliance

The Swift package has a portable MeetingCore library, a meeting-summarizer CLI, and a SwiftUI MeetingReview app. MeetingCore owns validated source ranges, transcript segments, neutral speaker labels, chair corrections, source-linked review items, processing provenance, quality warnings, and atomic local JSON storage. It does not import SwiftUI or AppKit. The CLI and review player load the same persisted record, so neither has a second business-data format. Local model executables are configured by path and run as separate processes. There is no remote inference fallback.

The accepted CLI amendment gives three independent operations. Transcribe creates a transcript-only record. Recognize is optional: the local FluidAudio diarizer assigns anonymous labels, while recognize name and recognize move let a chair correct the record. Summarize is optional and works with neutral or absent speaker labels. It invokes a local MLX language model, validates its structured output and source IDs, and saves minutes to the same record. The older import command remains for compatibility with the first prototype tests. The test-only fixture-reference option supplies invented data and must not be interpreted as model-quality evidence.

PBI-011.1, core and store: the record contract and atomic store are implemented. IT-1 starts the CLI in a separate process and reloads its output through MeetingStore. The child passed its six prescribed gates and was committed as 72fb8d4.

PBI-011.2, CLI: transcribe, recognize, recognize name, recognize move, and summarize are implemented and return the same record UUID across later steps. Invalid media, unknown IDs, missing configured models, and invalid corrections produce explicit errors. A synthetic three-command flow and a real FluidAudio transcription have run. Its six prescribed gates passed after help was corrected to mention the compatible import route; the audited completion commit is 5c5a7bf.

PBI-011.3, fixture and corrections: the checked-in invented 16 kHz mono WAV and paired reference JSON contain five timed turns from two speakers, a decision, an action, and an open question. The fixture generator was rerun outside the checkout; it produced 16.727125 seconds of audio with valid ranges and references. A fresh regeneration for this child again produced 16 kHz, one channel, 16-bit PCM, 16.727 seconds, and five reference turns. The chair named speaker_2 Ada and moved turn_1 to that label in a saved record. The synthetic summary then produced four review items. All six child gates passed; the audited completion commit is 1bae555.

PBI-011.4, review player: the SwiftUI app built and opened the real AMI record by ID. It displayed the transcript and 16 quality warnings; selecting the first warning sought the local audio to 19.3 seconds, and selecting a transcript turn sought to 4.7 seconds. The first AVKit VideoPlayer version crashed, so audio playback was changed to AVFoundation. A continuous-playback check was disruptive; the current version pauses after the selected source range and builds. That bounded playback has not been manually replayed since the user closed the app, and the app was not reopened for this child gate. The accepted build, manual open/seek, and CLI-created record integration criteria passed, as did all six child gates. The audited completion commit is aafa38e.

PBI-011.5, local-model integration: FluidAudio 0.17.4 with Parakeet TDT 0.6B v2, whisper.cpp with Whisper base.en, the FluidAudio offline diarizer, and MLX Swift LM 3.31.3 with locally staged Qwen3-4B-Instruct-2507 4-bit weights have all executed locally. The Fluid and whisper adapters each saved a timed synthetic transcript. Fluid transcribed the full approved AMI headset recording, and the diarizer saved labels and 16 warnings to record 87A64680-FD3C-44D4-9529-039E7071E46A. Xcode 27 with Metal Toolchain built MLX Swift's default.metallib. The MLX adapter generated and persisted source-linked minutes from the invented fixture in record 8DAAA0BB-C4A0-4863-9198-025E9FD4E643. On a natural 120-second AMI excerpt, the first word-level prompt produced truncated JSON. Source chunks made the response parseable; citations expand to original transcript IDs and an unsupported model owner is discarded. Record 4604E907-2EE9-4FE6-974A-8D22A5F9914D now contains the natural-audio minutes experiment. Its content quality failed, as explained below. The pinned adapter build, model artifact hash, local-only inference, transcript/source evidence, and all six child gates passed; the audited completion commit is b70ef21.

PBI-018, benchmark technical decisions: [the decision-facing report](ami_asr_benchmark.md) includes same-input accuracy, affected-speaker errors, alternate lapel input, repeated wall time, process resident memory, model footprint, timestamp diagnostics, diarization coverage, warning coverage and spillover, disconnected-network inference, and the MLX minutes experiment. On the common headset input, FluidAudio had 19.48% WER against 28.79% for whisper.cpp. Its affected-speaker reference-linked error rate was 27.78% against 58.55%. Three 120-second runs gave median wall times of 0.73 and 1.29 seconds. The diarizer found three clusters for four reference people and merged the low-quality participant with another speaker. The stored 16 warnings are therefore useful review cues, not reliable participant identification. The natural-audio MLX minutes converted a project goal into a decision, invented two actions, and generated two questions that were not asked. This is an observed quality failure, not a recommendation to use those minutes. The benchmark scoring was reproduced from stored outputs and all six PBI-018 gates passed. Sprint 3 will analyze the measurements and select architecture changes.

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

## Working CLI instructions

Run from the repository root on macOS with Swift and jq installed. The synthetic example needs no model weights. The WAV and reference JSON are paired test files; each transcribe command prints a new UUID. The later commands print that same UUID. The test-only fixture-reference option substitutes deterministic transcript, diarization, or minutes data at the corresponding step.

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

For real Fluid transcription, --settings must point to a JSON file with fluidExecutable and fluidModelDirectory. Real recognition also needs fluidDiarizerExecutable and fluidDiarizerModelDirectory. Real MLX summary needs mlxExecutable and mlxModelDirectory and a compiled mlx.metallib beside the executable. A whisper run needs whisperExecutable and whisperModelPath and selects --transcriber whisper. All paths refer to local executable or model files. For example, after staging them:

~~~bash
record_id="$(swift run meeting-summarizer transcribe /absolute/path/to/meeting.wav --transcriber fluid --settings /absolute/path/to/settings.json --store /private/tmp/meeting-real-store)"
swift run meeting-summarizer recognize "$record_id" --diarizer fluid --settings /absolute/path/to/settings.json --store /private/tmp/meeting-real-store
swift run meeting-summarizer summarize "$record_id" --summarizer mlx --settings /absolute/path/to/settings.json --store /private/tmp/meeting-real-store
cat "/private/tmp/meeting-real-store/$record_id.json" | jq '{id, segments: (.segments | length), qualityWarnings, reviewItems, processingParameters}'
~~~

The AMI benchmark is evidence of model behavior on one approved meeting, not a promise that natural minutes are accurate. Inspect each derived item against its cited source before using it.

A missing local WAV gives a clear error and does not create a record:

~~~bash
swift run meeting-summarizer transcribe tests/fixtures/no-such-meeting.wav --transcriber fluid --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo
printf 'status=%s\n' "$?"
~~~

The command prints Media file does not exist to stderr and exits with status 2. SwiftPM may print build progress first. The review app accepts a record UUID and the same store path; it was manually checked, but the real AMI audio preview was deliberately closed after playback became disruptive.

## Remaining limitations and next checks

The synthetic fixture proves contracts and corrections, not ASR or LLM accuracy. The AMI benchmark covers one English meeting and selected model sizes on one Mac. Speaker labels are anonymous and the poor-headset speaker was merged with another person. Warnings identify ranges for review but cannot yet reliably name the affected person. The natural-audio minutes fail content quality despite valid JSON and source links; no automatic publication should rely on them. The review player's bounded playback change and MLX model packaging need later checks. The six prescribed gates passed for each increment and the parent; architecture interpretation belongs to Sprint 3. No remote push has been made.
