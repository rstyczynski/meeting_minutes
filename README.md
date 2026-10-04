# Meeting Summarizer

## Vision

Meeting Summarizer is a private, local-first companion for macOS (OS X), with
iOS portability built in from the outset. macOS is the priority platform. It
helps a person leave any spoken or visual conversation with a trustworthy,
useful record of what was said, who said it, what was decided, and what needs
to happen next.

Meetings are easy to forget, difficult to reconstruct fairly, and prone to
losing decisions and commitments in scattered notes. The product turns the
spoken and visual context of a meeting into clear, attributable notes and
follow-up actions, so the record can be reviewed and acted on with confidence.

At the start of a meeting, the system recognizes speakers as neutral labels
such as “Speaker 1.” The operator assigns names to those labels. The interface
synchronizes the live transcript with the meeting's sound or video so the
operator can follow, identify, and correct attribution while the conversation
is happening.

For visual meetings, the initial product supports importing locally available
recordings in regular formats and live screen capture. Retention policy,
detailed privacy treatment, and the platform-specific permissions and capture
constraints will be decided in later requirements and risk work.

Trust depends on privacy. Meeting Summarizer must keep meeting audio, video,
transcripts, and meeting metadata on the user's devices: it must not send any
of that material to the internet. The initial product prioritizes macOS while
remaining portable to iOS; future scope and technical choices will be refined
through the project plan.

At this stage, Meeting Summarizer is fully local software. It has no internet
service or synchronization feature.

## Product approach

The product should use operating-system services and public libraries where
they are suitable for the task. It performs its meeting work with local AI
models; one or more models may be used when different parts of the job need
different capabilities. Model selection, packaging, and the division of work
between models remain implementation decisions, provided the local-only privacy
boundary is preserved.

The software is available in both UI and CLI modes. They share the same core
capabilities and may cooperate: a running UI can respond to command-line events
as well as keyboard and mouse input. The shared-core and event-coordination
architecture will be designed and validated in later work.

## Intended outcome

After a meeting, the user can understand the conversation's key points,
participants' attributable contributions, decisions, and next actions without
having to rely on memory or an external service holding their meeting data.

## Sprint 0 status

Sprint 0 is complete. The Product Owner accepted this vision as PBI-001 and
the tailored roadmap as PBI-002. Sprint 1 established the Inception baseline.
Sprint 2 remains active in managed mode. Its initial architectural prototype
and English benchmark were implemented and tested. The Product Owner then
added FR-11 English and Polish transcription validation to this sprint. Its
language-control CLI and paired multilingual model check have now run; all
Sprint 2 implementation gates have passed, with managed documentation review
pending. The natural-meeting minutes failure is a documented prototype result;
those drafts are not accepted as correct minutes.

The vision above describes the
longer-term product; the [SRS](docs/srs.md) states the current MVP boundary.

## Recent updates

### Sprint 0 — Vision and initial plan

The accepted vision establishes a fully local, macOS-first Meeting Summarizer that remains portable to iOS. It establishes local AI, live attribution, visual input, and cooperating UI/CLI modes as product constraints. The accepted plan starts Sprint 1 with system view, actors, and use cases before selecting the MVP.

### Sprint 1 — Inception baseline

The accepted MVP is a simple local macOS utility: import a recording through
the CLI, create an offline transcript, let the operator correct speaker
attribution while reviewing timestamped local media, and produce local minutes
and action items. The accepted [Software Requirements Specification](docs/srs.md)
and candidate [architecture](docs/architecture.md) use Swift/SwiftUI, a shared
Swift Package core, Swift Testing, and local-only storage. Live capture, direct
recording, visual attachments, alerts, search, export, permanent deletion, and
sharing are deferred.

### Sprint 2 — Architectural prototype and benchmark implemented

PBI-011 built and tested the Swift core, local store, CLI, review player, and
local model adapters. PBI-018 measured FluidAudio and whisper.cpp on
the same approved AMI meeting recording. The Product Owner added use cases and
requirements for low-quality audio, including warnings for the affected
speaker or source ranges and review of the original recording. The
[Sprint 2 design](progress/sprint_2/sprint_2_design.md) specifies the
experiment; the [implementation record](progress/sprint_2/sprint_2_implementation.md)
and [test record](progress/sprint_2/sprint_2_tests.md) state what has actually
run. The [benchmark report](progress/sprint_2/ami_asr_benchmark.md) gives
measured quality, speed, memory, model size, speaker attribution, and
low-quality-audio results with their limitations.

On the common AMI headset input, FluidAudio reached 19.48% word error rate
against 28.79% for whisper.cpp; the weak-headset participant remained hard to
identify because diarization merged two people. The local MLX adapter ran and
saved minutes, but its natural-audio sample invented actions and questions and
therefore failed content quality. The benchmark records the precise evidence
and leaves architecture interpretation for Sprint 3. All five PBI-011 child
increments, PBI-018, and the PBI-011 parent passed their separate six-gate
runs for that completed scope. The [Sprint 2 documentation review](progress/sprint_2/sprint_2_documentation.md)
shows the traceability and remaining limits. The [FR-11 design
amendment](progress/sprint_2/sprint_2_design.md) sets out the additional
language-control and validation work. The originally tested Parakeet v2 and
Whisper base.en models are English only. On a later fixed FLEURS subset of
five English and five Polish clips, Parakeet v3 made 11.49% and 3.41% word
error respectively; multilingual Whisper base made 18.39% and 27.27% in CPU
mode. Those clips are read speech, and neither `auto` run kept both languages
in an exploratory language-switch splice. The report has the exact references,
per-clip outputs, model identities, runtime, offline results, and limits.

The accepted CLI has three independent capabilities: `transcribe`, optional
`recognize`, and optional `summarize`. `transcribe` saves a transcript-only
record. `recognize` adds neutral speaker labels and permits a chair to assign
names or correct a segment. `summarize` saves minutes from the transcript,
using neutral labels when recognition is skipped. Each command updates or
creates the same local record. The old `import` command remains for
compatibility with the first prototype tests. Copyable working commands,
formatted `jq` output, prerequisites, and an error example are in the
[implementation record](progress/sprint_2/sprint_2_implementation.md).

For Product Owner validation, follow the [single-command demo and presenter
script](progress/sprint_2/demo/README.md): English and Polish transcription,
weak-audio warnings, operator review, neutral speaker labels, and minutes
inspection. The script uses the assets staged on the Sprint 2 Mac and
shows each fresh result and its limitations. The [benchmark
report](progress/sprint_2/ami_asr_benchmark.md) interprets model quality and
failures against references. The separate [functional test
record](progress/sprint_2/sprint_2_tests.md) contains the synthetic CLI
contract check and links the gate evidence.

The [Sprint 2 user manual](progress/sprint_2/user_manual.md) gives individual operations and
recovery guidance. The [Sprint 2 handover](progress/sprint_2/sprint_2_handover.md)
and [product walkthrough slides](progress/sprint_2/sprint_2_increment_demo_cli_ready_20261004.pptx)
present PBI-011 and PBI-018 outcomes and limitations. The [Product Owner
presentation brief](progress/sprint_2/sprint_2_product_owner_presentation.md)
is the concise guide to that review set. A real Polish Sejm
committee meeting now replaces single-speaker read speech in that walkthrough.
The [official-PDF transcription review](progress/sprint_2/tests/polish_sejm_pdf_transcription_review_20261002.md)
finds the main turns and decision recognizable, with word, name, acronym,
and numeric-unit errors requiring correction; no whole-meeting Polish WER
is claimed.

The approved staged-minutes experiment now preserves raw ASR, proposes
reversible fragment joins, supports audio-reviewed operator text
corrections, assigns each reading utterance to a topic, and validates
model responses before saving draft minutes. On the same saved real
meeting transcripts, it covered 21/21 AMI and 32/32 Sejm reading
utterances. A strict source audit accepted only 2/5 AMI and 2/4 Sejm
topic summaries. This is a measured direction for the next validation work,
not a quality pass for generated minutes.

The [trial report](progress/sprint_2/tests/multistage_minutes_trial_20261004.md)
gives measured runtime, memory, cited examples, and preserved failed
runs; the [quality review slides](progress/sprint_2/sprint_2_quality_review_20261004.pptx)
show the control architecture and Product Owner decision point. These
results are architecture evidence, not accepted participant minutes.

The minutes citation crash was repaired, but the resulting draft still
contains unsupported items. A longer [Department of Energy meeting
fixture](progress/sprint_2/doe_itiac_day2_fixture.md) produced 4,216 English
transcript segments and eight speaker labels; both tested local minutes
models failed to save structured output on its 30-minute excerpt. The
Product Owner has directed that the minutes failure be shown as a prototype
finding. Live handover acceptance and managed documentation approval remain
pending.

For a complete local Sprint 2 quality check, run
`tests/run-sprint-gates.sh progress/sprint_2` from the repository root. It
executes the six required smoke, unit, and integration gates and saves one
timestamped log per gate; [the test profile](docs/test-profile.md) explains
the levels and the optional log label.
