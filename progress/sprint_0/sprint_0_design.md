# Sprint 0 — Vision and initial plan design

## PBI-001 — Establish the product vision

Status: Accepted

### Requirement summary

Create a concise, durable product vision that communicates the user value,
problem, intended outcome, macOS-first delivery with iOS portability, and the
non-negotiable local-first privacy boundary.

### Feasibility analysis

This is a documentation deliverable based on the Product Owner's supplied
intent; no platform APIs, services, implementation stack, or external accounts
are required. The vision is feasible as written.

### Design overview

`README.md` becomes the accepted vision source. It is organized around the
product identity, the problem and value, the privacy constraint, and the
intended post-meeting outcome. It deliberately does not choose capture,
transcription, diarization, storage, synchronization, export, or model
technology; those choices require Inception requirements and risk work. Later
design must treat macOS as the priority target while preserving iOS portability.
It may use OS services and public libraries and must use local AI model(s),
with model responsibilities selected in later design work.

The product exposes both UI and CLI modes over shared core capabilities. A
running UI may react to CLI-originated events in addition to keyboard and mouse
input. Later architecture work must validate the shared-core boundary, local
event model, lifecycle behavior, and macOS-to-iOS portability.

### Risks and boundaries — resolution

The following are resolved product decisions for Sprint 0. They constrain later
architecture work; they are not open questions.

- **Speaker attribution:** At meeting start, assign local neutral labels (for
  example, “Speaker 1”). The operator assigns names. Synchronize the live
  transcript with meeting sound or video so the operator can review and correct
  attribution during the conversation.
- **Visual input:** Support importing locally available recordings in regular
  formats and live screen capture.
- **Privacy and locality:** The software is fully local at this stage. It has
  no internet service or synchronization feature. Meeting audio, video,
  transcripts, and metadata remain on the user's devices.
- **AI and dependencies:** Use OS services and public libraries where suitable,
  and use one or more local AI models for the work.
- **Interfaces:** Provide both UI and CLI modes over shared core capabilities;
  a running UI can react to CLI events as well as keyboard and mouse input.

The following implementation details are deliberately deferred, rather than
assumed: attribution confidence and correction persistence; recording-format
support; retention; platform permissions and capture mechanics; individual
model selection, responsibilities, packaging, quality, hardware requirements,
and licensing; the UI/CLI event model, conflict handling, and lifecycle; and
the exact approach for iOS portability. Later work must resolve them without
violating the decisions above.

### Testing strategy

#### Recommended Sprint Parameters

- **Test:** none — PBI-001 creates no production code.
- **Regression:** none — there is no existing executable product to regress.

#### Review evidence

Product Owner review must confirm that the README clearly states the intended
user, value, problem, outcome, supported platform intent, and the prohibition
on internet transmission of meeting audio, video, transcripts, and metadata.

### Success criteria

The Product Owner accepts `README.md` as an understandable, internally
consistent product vision.

## PBI-002 — Derive the initial project plan from the vision

Status: Accepted

The accepted vision supplied the traceability basis for the tailored roadmap and Sprint 1 proposal. The Product Owner accepted the proposal, and the root `BACKLOG.md` and `PLAN.md` now contain the project-specific plan.

## Test specification

Sprint Test Configuration:

- Test: none
- Regression: none
- Mode: managed

No automated tests, test skeletons, component manifests, or new-test manifest
are applicable. The quality evidence for this non-code sprint is the Product
Owner's documented review.

### Traceability

| Backlog Item | Review evidence |
|--------------|-----------------|
| PBI-001 | Product Owner acceptance of `README.md` |
| PBI-002 | Product Owner acceptance of the tailored roadmap and Sprint 1 proposal |

## Design approval status

PBI-001 and PBI-002 accepted.
