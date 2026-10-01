
# Sprint 2 — Implementation record

This record is updated during Sprint 2 construction. A completed artifact is
listed only after it builds or its behavior is verified. The final test and
benchmark results will be recorded separately and linked here.

## Evidence required by RUP Strikes Back

The canonical constructor procedure requires implementation details for each
assigned backlog item, design compliance, code artifacts and their status,
test results, known issues, and user instructions with prerequisites, options,
working command examples, expected output, and an error case. Functional test
sequences and their results belong in `sprint_2_tests.md`; the manager also
requires timestamped quality-gate logs. This record tracks those fields as
work proceeds. The Product Owner's paragraph preference replaces narrative
tables; the progress board keeps its required table.

## Implementation overview and RUP checkpoint

The real-time Sprint and PBI states are `under_construction` on
`PROGRESS_BOARD.md`. The design is `Accepted`. Sprint 2 covers PBI-011 and its
five children, plus PBI-018. This is an Elaboration prototype; retention for
production will be decided from later validation evidence.
The accepted design covers the original combined import and the approved
FR-09/FR-10 experiment. The requested three-command CLI revision is proposed
and waits for managed-mode design approval before implementation.

For a hands-on view of what works today, go to Working synthetic import below.
It imports an invented local meeting, prints the saved transcript and review
items, and needs no model weights. Real-model integration and generated
minutes are still under construction; their intended command and missing
prerequisites are stated separately below.

The canonical `tests/run.sh` and `new_tests.manifest` are the prescribed gate
entry points. Their unit and integration wrappers have been repaired from
stale XCTest filters to the approved Swift Testing case identifiers. Both
preliminary new-only runs pass. For the completed PBI-011.1 core/store
increment, all six prescribed quality gates passed with timestamped logs
recorded in [the functional test record](sprint_2_tests.md). Other children
and PBI-018 remain under construction and require their own completion
checks.

## PBI-011 — Executable prototype

### PBI-011.1 — Core and local store

The Swift package now has a portable `MeetingCore` library with validated
source ranges, transcript segments, review items, provenance fields, and an
atomic JSON record store. It has no SwiftUI or AppKit import. The package
builds on the working Mac. Core unit tests and all six prescribed gates pass.
IT-1 now runs the CLI as a separate process and loads its persisted synthetic
record through `MeetingStore` in the test process, satisfying the fresh-process
reload acceptance check. Status: tested for this bounded core/store child.

### PBI-011.2 — CLI import

`meeting-summarizer` now parses local WAV import, backend selection, settings,
store location, and a synthetic fixture reference. It rejects invalid backend
names and missing configuration. The CLI builds. One synthetic fixture import
created a record that was reloaded and inspected; the formal gate remains open.

### PBI-011.3 — Derived record and corrections

The synthetic meeting generator, checked-in WAV, and reference JSON provide
five invented turns from two voices. The fixture is 16 kHz mono PCM with
nonempty speech, valid turn ranges, and cited decision, action, and open
question annotations. Fixture adapters, minutes source validation, speaker
renaming, and segment reassignment are implemented. Integration verification
is pending.

### PBI-011.4 — Review player

A SwiftUI review executable builds. Its implementation loads a record by ID
from the shared store, presents transcript and review items, and offers source
seeking with AVPlayer. A manual UI run and the specified integration checks
remain, so that behavior is not yet verified.

### PBI-011.5 — Local-model integration

The common transcription contract and process adapters for whisper.cpp and
FluidAudio are in place. The FluidAudio helper is isolated in
`experiments/FluidAdapter/`; its pinned 0.17.4 dependency resolved and the
helper builds in release mode and now runs inference against local model
weights. An explicit `--download-models ROOT` setup mode staged v2 Core ML
weights outside Git. The first run revealed that FluidAudio's returned path
did not name the actual repository folder; the helper was corrected and
rebuilt successfully. Speaker diarization and LLM minutes generation are not
yet integrated into real-model imports.

Using the same 16-second synthetic WAV and locally staged models, the current
CLI saved a FluidAudio record
`C7BFBF64-4CBC-42DA-B03A-FEAEE681BE82` with 45 timed segments,
backend `fluid`, model revision `parakeet-tdt-0.6b-v2`, and zero review
items. It saved a whisper.cpp record
`7890A5EE-1EE4-40F5-BDE2-43720714F8F6` with five timed segments,
backend `whisper`, model revision `ggml-base.en.bin`, and zero review
items. Both records are outside Git under
`/private/tmp/meeting-minutes-ami/real_asr_records`. These are adapter and
record-contract checks, not reference-scored ASR quality evidence.

## PBI-018 — Benchmark technical decisions

The paired synthetic audio/reference fixture is ready. The same-audio
benchmark has a preliminary full-headset quality result from both real
ASR engines on the approved natural meeting. Separate lapel runs indicate
how a changed microphone mix affects the documented poor-headset speaker
and overall accuracy. Three repeated 120-second runs per engine record
elapsed time, process resident memory, and staged model footprint. The
scores, resource measurements, scoring normalization, model identities,
and limits are in [the benchmark evidence](ami_asr_benchmark.md).
Speaker attribution, low-quality warnings, timing error, actual offline
operation, and minutes-quality results remain outstanding. Sprint 2 records
measurements and their limits;
Sprint 3 interprets them for architecture decisions.

The Product Owner approved AMI meeting ES2002a. Its headset and lapel mixes
and manual annotations are downloaded outside Git, with source links,
license, integrity checks, and SHA-256 hashes recorded in
[the fixture evidence](ami_es2002a_fixture.md). The known headset problem
for one participant makes this meeting useful for FR-09 and FR-10 validation. A
preliminary annotation-guided signal probe found that speaker A's individual
headset track has much lower speech level than the corresponding lapel track;
speaker B's tracks did not show that pattern. The official meeting metadata
maps the documented participant 1 problem to annotation speaker A. The exact
commands, readings, and limits are in the fixture evidence. This targets the
critical test. Reference-linked errors have now been measured for A, but no
automatic quality warning or speaker-attribution score has been produced.
FR-09 and FR-10 remain unvalidated.

The whisper.cpp source was built locally outside Git at commit
`6e4ab854f67f743900934a703d5603419384c961` with the Metal backend. The
`base.en` model is staged outside Git at
`/private/tmp/meeting-minutes-whisper.cpp/models/ggml-base.en.bin`
(147,964,211 bytes; SHA-256
`a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002`).
An initial 120-second probe on the approved AMI headset mix completed and
produced a JSON transcript outside Git. Its schema includes timed
`transcription` entries compatible with the adapter's expected offsets.
This is a tool and format check only; the full same-audio comparison,
reference scoring, repeated runtime measurement, and low-quality-audio
result remain pending.

## Quality and environment

`swift build` passes for the root prototype. The available Apple Command Line
Tools omit a directly importable XCTest module. The Product Owner chose the
open-source Swift Testing package for this sprint. Its pinned 6.3.2 package
now links after the test targets supply the Command Line Tools interop library
path. A preliminary `swift test` run passed 12 tests in two suites. The formal
new-work and regression gates remain pending. No model-quality result is
claimed yet.

The main package has no speech-model dependency, so a normal build does not
download model weights. The FluidAudio experiment package resolves its own
dependency separately. No external push or release has been performed.

## Design compliance and code artifacts

The main `Package.swift` keeps model dependencies outside the core package.
`Sources/MeetingCore/` implements the record, local store, configuration,
import contracts, and adapter boundary. `Sources/MeetingCLI/` provides the
local import entry point. `Sources/MeetingReview/` provides the SwiftUI review
entry point. `tests/fixtures/` holds generated synthetic evidence. The
FluidAudio experiment helper is being verified in
`experiments/FluidAdapter/`. The approved design's real-model minutes,
diarization, and two-engine measurement requirements remain open.

`Package.swift` and `Package.resolved` define the root targets and pinned test
dependency; they build and twelve selected Swift Testing cases have run.
`Sources/MeetingCore/` contains the record contract, store, importer, and
adapter boundary; the unit and fixture-backed integration tests exercise
portions of it. `Sources/MeetingCLI/` contains the import command; help, one
fixture import, and a missing-media error were run as separate processes.
`Sources/MeetingReview/` contains the SwiftUI player; compilation passed,
manual operation is pending. `tests/fixtures/` contains the generator, WAV,
and reference; the checked-in fixture was validated, while fresh regeneration
is pending. `tests/run.sh`, its suite scripts, and the Sprint 2 manifest are
the RUP test artifacts; preliminary new-only unit and integration runs pass,
but formal gate execution is pending. `experiments/FluidAdapter/` builds;
synthetic inference passes, while diarization remains pending. The
whisper.cpp executable and model were built or staged outside Git; its
adapter also passes a synthetic end-to-end CLI run.

The verified explicit FluidAudio setup command is:

~~~text
swift run --package-path experiments/FluidAdapter -c release meeting-fluid-asr --download-models /private/tmp/meeting-minutes-models
~~~

This is a preparation command that downloads model weights under the local
root directory; it is not a meeting-processing command. The first version
of the helper downloaded the weights but printed a nonexistent requested
path because FluidAudio stores them under its repository folder. The helper
now reports `/private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v2` after
checking for its vocabulary file; the corrected command ran successfully
and printed that path. An initial Fluid inference probe produced timed JSON
but Core ML appended a diagnostic to standard output after the JSON, making
the original stdout adapter response invalid. The helper and process adapter
now use `--output-json FILE` and read that dedicated file. The corrected
helper and root package both build, the dedicated JSON file parses, and the
current CLI successfully saves a FluidAudio transcript from synthetic audio.
The normal inference form loads staged assets locally and does not download
at runtime.

## User documentation in progress

### Three independent CLI capabilities — pending revised design and code

The Product Owner requested `transcribe`, optional `recognize`, and optional
`summarize`. These are documented in
[the proposed changes](sprint_2_proposedchanges.md), but the current executable
still implements the older combined `import` command shown below. The
following commands are the proposed user workflow; they are **not yet working
CLI examples** and must not be used as evidence of implementation.

`transcribe` will accept a local recording and a selectable ASR backend. It
will create a durable record with timed text and neutral or unknown speaker
labels, and no minutes:

~~~text
meeting-summarizer transcribe <local.wav> --transcriber fluid|whisper [--settings settings.json] [--store directory]
~~~

`recognize` will optionally assign neutral speaker turns from local audio.
The chair will also be able to assign a name to a speaker ID and move a
misattributed segment. Diarization alone does not identify a person:

~~~text
meeting-summarizer recognize <record-id> --diarizer fluid [--settings settings.json] [--store directory]
meeting-summarizer recognize name <record-id> <speaker-id> <display-name> [--store directory]
meeting-summarizer recognize move <record-id> <segment-id> <speaker-id> [--store directory]
~~~

`summarize` will read the saved transcript and generate minutes only when
requested. It will use chair-assigned names where available and neutral
labels otherwise. Real generation will require a local LLM and weights:

~~~text
meeting-summarizer summarize <record-id> --summarizer mlx [--settings settings.json] [--store directory]
~~~

The revised functional tests in [the test record](sprint_2_tests.md) are
pending. A separate low-quality-audio experiment will check whether the
pipeline flags the affected speaker or source ranges; the `recognize`
command alone must not be interpreted as proof of FR-09.

### Working synthetic import

The prototype requires macOS, Swift 6, and a local WAV recording. The
deterministic fixture path also requires the paired reference JSON in
`tests/fixtures/`. A normal model import additionally requires local model
weights and a configured local adapter executable; missing assets cause an
explicit error. The CLI accepts `import`, `--transcriber fluid|whisper`,
`--settings`, `--store`, and the test-only `--fixture-reference` option.
The verified fixture example, run from the repository root, is:

```bash
record_id="$(swift run meeting-summarizer import tests/fixtures/synthetic_meeting.wav --transcriber fluid --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo)"
printf '%s\n' "$record_id"
```

Expected output is one UUID, such as
`9E7DAFA1-D474-41D2-B316-F51C9B2E61AF`; each import creates a new UUID.
With jq installed, the following command displays the saved record for a
human reader. Run it in the same shell immediately after the import above:

~~~bash
jq -r '
  "Meeting: \(.id)",
  "Source: \(.sourcePath)",
  "Backend: \(.backend) (\(.modelRevision))",
  "",
  "Transcript:",
  (.segments[] | "  [\(.range.startSeconds)-\(.range.endSeconds)s] \(.speakerID // "unknown"): \(.text)"),
  "",
  "Review items:",
  (.reviewItems[] |
    "  \(.kind): \(.text) [source: \(.sourceSegmentIDs | join(", "))]" +
    (if .ownerSpeakerID then " [owner: \(.ownerSpeakerID)]" else "" end))
' "/private/tmp/meeting-sprint2-demo/$record_id.json"
~~~

Representative output (the meeting ID changes on each import):

~~~text
Meeting: 61D514FF-684A-4556-AB92-E56730F61F1E
Source: /Users/rstyczynski/projects/meeting_minutes/tests/fixtures/synthetic_meeting.wav
Backend: fluid (synthetic-reference-v1)

Transcript:
  [0-2.325s] speaker_1: Let's review the release plan for Friday.
  [2.775-5.304s] speaker_2: The audio import is ready for a small test.
  [5.754-9.565s] speaker_1: We decide to test both transcription engines on the same recording.
  [10.015-12.542s] speaker_2: I will write the reference transcript by Thursday.
  [12.992-16.219s] speaker_1: Who will check the speaker labels? That is still open.

Review items:
  decision: Test both transcription engines on the same recording [source: turn_3]
  action: Write the reference transcript by Thursday [source: turn_4] [owner: speaker_2]
  openQuestion: Who will check the speaker labels? [source: turn_5]
~~~

The display starts with the meeting ID, local source path, and
fluid (synthetic-reference-v1). It shows five timed speaker turns, then a
decision sourced to turn_3, an action sourced to turn_4 with speaker_2 as
owner, and an open question sourced to turn_5. To inspect every stored field,
run cat on the same JSON file:

~~~bash
cat "/private/tmp/meeting-sprint2-demo/$record_id.json"
~~~

The stored record contains five transcript segments and three source-linked
review items. `--transcriber` chooses `fluid` or `whisper`; `--settings` reads
a local configuration path; `--store` chooses the record directory; and the
test-only `--fixture-reference` supplies the synthetic reference. It is not
evidence of ASR accuracy. A normal import requires local model files and its
adapter executable.

### Real meeting import — implementation pending

The intended real-audio CLI form is:

```bash
swift run meeting-summarizer import /absolute/path/to/meeting.wav --transcriber fluid --settings /absolute/path/to/settings.json
```

The settings JSON must identify a local `fluidModelDirectory` and
`fluidExecutable`; selecting `whisper` instead requires a local
`whisperModelPath` and `whisperExecutable`. The whisper.cpp executable and
base.en model and Fluid weights are staged outside Git. Both CLI adapters
have been verified end to end on the synthetic WAV, but neither has completed
a reference-scored natural-meeting benchmark. The current real-model path
also uses an empty minutes
generator, so even successful transcription would not yet produce the
source-linked meeting minutes required by the accepted design. This command
is an interface example, **not a verified working workflow**. Do not treat
the synthetic import above as a benchmark or full product demonstration.

### Missing-media error

The verified error example is:

```bash
swift run meeting-summarizer import tests/fixtures/no-such-meeting.wav --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo
printf 'status=%s\n' "$?"
```

SwiftPM may print its usual build progress first. The CLI then prints
`Media file does not exist` on stderr, and the second line prints `status=2`.
This failure must not create a new record. Review-player usage will be added
after manual operation is checked.

## Known issues and limits

Whisper base.en weights have been staged and a 120-second tool probe ran, but
neither transcription backend has produced a reference-scored result. The
FluidAudio timing and diarization path remain under construction. The first integration
tests cover the shared core with fixture adapters; stronger automated CLI
process checks and a manual review-player check are still required by the
design.

## Sprint implementation summary

Overall status remains `under_construction`, and the increment is not ready
for production use. The package and fixture-path prototype build. Twelve
selected tests, one CLI import, and one missing-media error passed preliminary
checks. The Swift Testing switch resolved the Command Line Tools XCTest
limitation. The FluidAudio dependency was upgraded to pinned 0.17.4 after
upstream 0.12.4 failed under Swift 6.3. Synthetic real-model inference now
works through both adapters; speaker diarization, local LLM minutes,
two-engine measurement, UI operation, and the
formal RUP gates remain open. Test and user documentation are in progress.
