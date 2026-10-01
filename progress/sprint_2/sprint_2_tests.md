# Sprint 2 — Functional test record

The formal RUP quality gates passed for the bounded PBI-011.1 core/store
increment. Other Sprint 2 children and PBI-018 remain under construction;
their completion evidence is still pending.

## Test environment and prerequisites

Run these commands from the repository root on macOS with Swift 6.3.3. The
Swift test targets use the pinned open-source Swift Testing package. The
synthetic WAV and reference JSON contain invented content. Real-model runs
also require local executables and model weights staged outside Git; their
setup and checks are pending. No account, token, or network service is needed
to replay the synthetic fixture.

## PBI-011 functional checks

### CLI help and package build

Purpose: Confirm that the prototype compiles and its CLI advertises local
import. Run:

```bash
swift build
swift run meeting-summarizer --help
```

Expected output: `Build complete!` followed by usage beginning
`meeting-summarizer import <local.wav>`. Status: PASS in a preliminary
construction run; the A1 and B1 smoke gate logs remain pending.

### Synthetic import and source references

Purpose: Confirm an executable CLI import creates a durable record with
source-linked derived output. Run:

```bash
swift run meeting-summarizer import tests/fixtures/synthetic_meeting.wav --transcriber fluid --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo
```

Expected output: one UUID. The corresponding JSON file under the selected
store must contain five timed segments, one decision cited to `turn_3`, one
action cited to `turn_4` with `speaker_2` as owner, and one open question cited
to `turn_5`. A preliminary run returned
`9E7DAFA1-D474-41D2-B316-F51C9B2E61AF`; inspection confirmed the stated
record fields. Status: PASS for this fixture run. Repeating the command
creates a different UUID.

### Missing media error

Purpose: Confirm failure is explicit and does not create a replacement record.
Run:

```bash
swift run meeting-summarizer import tests/fixtures/no-such-meeting.wav --fixture-reference tests/fixtures/synthetic_meeting_reference.json --store /private/tmp/meeting-sprint2-demo
printf 'status=%s\n' "$?"
```

Expected output: optional SwiftPM build progress, then
`Media file does not exist` on stderr, followed by `status=2`. A preliminary
run returned that error and exit status. Status: PASS for the error path.

### Unit and integration contracts

Purpose: Verify record validation, atomic persistence, corrections, source
links, backend configuration, fixture format, and normalized adapter output.
Run:

```bash
swift test
```

Expected output: 12 tests in two suites pass. The preliminary construction
run passed all 12. Status: PASS for the current suite. The formal manifest
and regression gates also passed for PBI-011.1, as recorded below. IT-1 now
checks an actual CLI-created record in a separate process. Manual
review-player checks and stronger assertions for other children remain.

The preliminary prescribed-runner checks are copy-pasteable:

```bash
tests/run.sh --unit --new-only progress/sprint_2/new_tests.manifest
tests/run.sh --integration --new-only progress/sprint_2/new_tests.manifest
```

Expected output: each named wrapper runs exactly one Swift Testing case and
the runner ends with `all available test scripts passed`. Both commands pass
after the stale XCTest filters were corrected. This verifies runner wiring;
it preceded the formal A2/A3 gates. IT-1 was subsequently strengthened to
run the actual CLI and reload its saved record in the test process. Accepted
IT-3, IT-4, IT-5, and IT-6 still need stronger end-to-end assertions.

### Real ASR adapter checks on the synthetic WAV

The current `import` CLI was run twice with local model settings and the same
synthetic WAV, once with `--transcriber fluid` and once with `--transcriber
whisper`. Both commands exited successfully and saved local records. JSON
inspection found 45 timed segments for FluidAudio v2 and five for
whisper.cpp base.en, with matching backend and model provenance and zero
review items in each. Status: PASS for adapter execution and stored-record
format. The exact record IDs and local paths are in the implementation
record. The fixture's naturalness and these segment counts do not establish
word accuracy, speaker attribution, or minutes quality. The same-audio AMI
benchmark remains PENDING.

### Requested three-command CLI coverage — pending design approval

The Product Owner requested independent `transcribe`, optional `recognize`,
and optional `summarize` commands. The current executable and the PASS results
above apply only to `import`; they do not validate these commands. After the
managed-mode design revision is accepted, the Test Architect must update the
design test specification, runnable skeletons, component manifests, and
`new_tests.manifest` before construction of the revised commands.

The `transcribe` functional test must run the synthetic WAV through the
test-only fixture adapter, capture its record ID, and inspect the saved JSON
for timed transcript segments, backend provenance, neutral speaker labels,
and an empty review-item collection. A missing-media run must exit with a
clear error and leave the store unchanged. Both supported backend selections
must be exercised against the same input for the benchmark path.

The optional `recognize` tests must verify that diarization updates the same
record with neutral speaker turns, chair name assignment survives a fresh
load, and moving a segment preserves its source range. Unknown record,
speaker, and segment IDs must fail without corrupting the prior record.
Skipping recognize must leave a transcript-only record usable by summarize.

The optional `summarize` tests must verify that a separate invocation adds
source-linked review items to the existing record. One run must use
chair-assigned names; another must run without recognition and retain neutral
labels. A missing local LLM or an invalid source reference must fail
explicitly without destroying the transcript. Synthetic fixture-derived
minutes must be labeled as such and must not count as real-model quality.

These are PENDING specifications, not executed test sequences or PASS claims.
The implementation record labels the proposed commands as non-working until
their code and copy-paste functional sequences have been verified.

## PBI-018 benchmark checks

The FluidAudio and whisper.cpp experiments must run on the identical pinned
audio and use the same reference transcript and scoring normalization. The
result record must include revisions, fixture hashes, word error rate, timing
error, elapsed time over repeated runs, peak memory, model footprint, and
explicit limits. Status: PARTIAL. Both engines produced timed JSON for the
same full AMI headset mix. Paired WER and reference-speaker error, separate
lapel-input results, three runtime repeats per engine, process resident
memory, and staged model footprint are in
[the benchmark evidence](ami_asr_benchmark.md). Boundary timing error,
speaker attribution, automatic warnings, replay/recovery, disconnected
operation, and minutes quality are PENDING.
The Product Owner approved AMI ES2002a for the natural
meeting check, and its headset and lapel
mixes plus manual annotations were downloaded outside Git and verified.
Their exact paths, hashes, sources, license, and limits are recorded in
[the fixture evidence](ami_es2002a_fixture.md). The low-quality-audio
check is critical and PARTIAL: same-headset ASR and reference-speaker errors
have been scored; speaker attribution and warning detection remain pending.
Inspect quality warnings and their source ranges, then compare the lapel
mix as a distinct recovery condition. Verify that the original stays
available and suspect ranges can be replayed, then record separate FR-09
participant-warning and FR-10 review/recovery outcomes. Official meeting
metadata identifies speaker A as the participant with the headset problem;
an annotation-guided RMS probe supports that mapping. Methods and
measurements are in the fixture evidence. No speaker-attribution or automatic
quality-detection result exists yet.

## Quality gates and artifacts

The required new-work gates are A1 smoke, A2 unit, and A3 integration, followed
by full regression B1 smoke, B2 unit, and B3 integration. All six passed for
the PBI-011.1 completion check. A1 first failed because SwiftPM could not
apply its nested sandbox; the rerun outside that sandbox passed. This was an
environment failure, not a product-test assertion failure. A3 and B3 were
rerun after IT-1 was strengthened, and both passed again. The complete log
names, each under `progress/sprint_2/`, are:

`test_run_A1_smoke_20261001_090052.log` (sandbox failure),
`test_run_A1_smoke_20261001_090116_retry1.log` (PASS),
`test_run_A2_unit_20261001_095313.log` (PASS),
`test_run_A3_integration_20261001_095611.log` (PASS),
`test_run_B1_smoke_20261001_095330.log` (PASS),
`test_run_B2_unit_20261001_095337.log` (PASS), and
`test_run_B3_integration_20261001_101632.log` (PASS).
The earlier A3 and B3 logs ending `_095322.log` and `_095343.log`
also passed before IT-1 changed.
`swift build` passed. IT-1 ran the CLI in a separate process, parsed its UUID,
and reloaded the saved synthetic record through `MeetingStore`, verifying five
segments and its source path. This satisfies PBI-011.1's fresh-process reload
criterion. The real-model benchmark and UI operation are incomplete, so the
Sprint 2 parent items cannot yet be marked tested.
