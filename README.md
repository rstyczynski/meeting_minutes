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
Sprint 2 is active in managed mode and is building an architectural prototype
and benchmarking its technical choices. The vision above describes the
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

### Sprint 2 — Architectural prototype and benchmark in progress

PBI-011 is constructing the Swift core, local store, CLI, review player, and
local model adapters. PBI-018 will benchmark FluidAudio and whisper.cpp on
the same approved AMI meeting recording. The Product Owner added use cases and
requirements for low-quality audio, including warnings for the affected
speaker or source ranges and review of the original recording. The
[Sprint 2 design](progress/sprint_2/sprint_2_design.md) specifies the
experiment; the [implementation record](progress/sprint_2/sprint_2_implementation.md)
and [test record](progress/sprint_2/sprint_2_tests.md) state what has actually
run. Real-model measurements and formal quality gates are pending.

The Product Owner also requested three independent CLI capabilities:
`transcribe`, optional `recognize`, and optional `summarize`. The current
executable still has a combined `import` command for the synthetic fixture.
The [CLI change proposal](progress/sprint_2/sprint_2_proposedchanges.md)
records the requested commands. They are not working commands yet; the
accepted design and functional tests require revision before their
implementation proceeds in managed mode.
