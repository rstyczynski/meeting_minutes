# Inception baseline — Meeting Summarizer

Status: Accepted

## System view

Meeting Summarizer is a local macOS utility with CLI ingestion and a focused
SwiftUI review player. It receives a recording already present on the
operator's device, creates an offline meeting record, and keeps the recording,
transcript, speaker labels, minutes, actions, and metadata on that device.
It does not call an internet service or synchronize meeting data.

The MVP has one application user: the local operator. Meeting chair,
participant, and follow-up owner are meeting-record roles used by the system
and its use cases. The operator assigns and manages them locally. They do not
imply accounts, authentication, or permissions in this release, but provide a
coherent basis for later permission design.

The initial release has no organization administrator, cloud service,
integration, participant account, or cross-device synchronization role.

### Platform constraints

macOS protects user media and data, constraining local storage behavior and any
future capture capability. The shared core must remain free of macOS-only UI
and capture dependencies so an iOS adapter remains possible.

## Stakeholders and meeting-record roles

### Local operator

The local operator produces and reviews a useful record without leaving the
device. They start imports, control local data, and use both the UI and CLI.

### Meeting chair

The meeting chair is a role performed by the single local operator, not a
separate application user. In that role, the operator makes participant
attribution trustworthy by renaming neutral labels and correcting transcript
attribution.

### Meeting participant

A participant is represented accurately and with appropriate consent. They may
be named by the chair, but no separate account is created. In the MVP, the
local operator manages this role.

### Follow-up owner

A follow-up owner is the person named for an action item. This is action
context, not a system user in the MVP; the local operator manages it locally.

## Use cases and success criteria

### Import a recording

The local operator supplies a local audio or video recording as a CLI argument.
It becomes a local meeting record without network use. A UI file picker is not
required for the MVP.

### Review the transcript

The local operator follows time-ordered transcript segments against the local
source recording. The review player can seek the local recording to a selected
segment's timestamp.

### Attribute speakers

The local operator, acting as meeting chair, renames neutral speaker labels to
participants and corrects an incorrectly attributed segment after reviewing
the corresponding local media at its timestamp.

### Review minutes and actions

The local operator reads locally generated summary, decisions, and action items
with links to relevant transcript time ranges.

### Coordinate UI and CLI

The CLI and review player use the same local meeting-record store. After import,
the CLI prints a local record identifier; the operator opens that record in the
review player. No background application, event subscription, or automatic
cross-process refresh is required.

## Requirements

### Functional requirements

#### FR-01 — Import local recording

The CLI shall accept a local recording path as an import argument and reject
nonexistent or unsupported input without copying data to a network service.

#### FR-02 — Create local meeting record

The system shall create a local meeting record containing source identity,
timestamps, transcript segments, neutral speaker labels, minutes, decisions,
actions, and source references.

#### FR-03 — Generate transcript

The system shall generate a timestamped local transcript from the imported
recording through a replaceable local transcription adapter.

#### FR-04 — Correct speaker attribution

The system shall assign neutral speaker labels and allow the meeting chair to
rename labels and correct a segment's attribution.

#### FR-05 — Generate source-linked minutes

The system shall generate local minutes containing a summary, decisions, action
items, and open questions. It may retain and show source references for an
operator's review, but those references are optional and are not part of the
participant-facing minutes delivery.

#### FR-06 — Share local records between CLI and review player

The CLI and review player shall use the same local meeting-record contract and
store. The CLI shall print the created record identifier, and the review player
shall open a record by that identifier. No background application, event
subscription, or automatic refresh is required.

### Non-functional requirements

#### NFR-01 — Local-only data

Meeting audio, video, transcripts, metadata, and derived records remain local and are not sent to the internet. Offline fixture validation must show no network dependency, and architecture review must confirm no network client.

#### NFR-02 — Portable core

Core meeting-domain code must not depend on SwiftUI, AppKit, or a capture API. Core XCTest tests must compile and run without the app target.

#### NFR-03 — Replaceable platform adapters

Platform adapters must be replaceable so iOS can reuse core, local-model contracts, and record-storage semantics. The candidate architecture must keep the core separate from macOS adapters.

#### NFR-04 — Source traceability

When an operator chooses review mode, the system can trace a transcript segment, decision, or action to a time range in the imported local recording. Participant-facing minutes must remain understandable without source references. A synthetic-fixture integration test must verify source references when present.

#### NFR-05 — Non-destructive failure handling

Processing failures are explicit and preserve the source recording and already-completed local results. Error-path tests must verify that no destructive overwrite occurs.

## Initial release scope

Included:

- A single local macOS operator.
- CLI import of a local recording using a positional or named input argument.
- Offline transcript creation with neutral labels.
- Chair-managed participant naming and attribution correction.
- Local minutes, decisions, action items, and open questions; optional source
  references are available only for operator review.
- A local SwiftUI review player that opens a CLI-created local record and
  synchronizes transcript selection with local-media seeking.

Excluded:

- Live screen capture and direct recording.
- Visual attachment extraction.
- Alerts, search, export, permanent deletion, automatic sharing, and cloud sync.
- Participant accounts, organization administration, and policy management.
- Persistent facial identification.

## Candidate Product Backlog

This is a proposed Product Owner backlog ordering; it does not amend the root
backlog until accepted.

1. Import a local recording into a durable local meeting record.
2. Create an offline timestamped transcript through a local-model adapter.
3. Support chair-managed speaker naming and attribution correction.
4. Generate source-linked local minutes, decisions, actions, and open questions.
5. Open and review a local meeting record by its CLI-created identifier in the SwiftUI review player.
6. Validate privacy, local-model feasibility, record-opening flow, and iOS portability through an architectural prototype.
7. Add deferred capture, retention, search, export, and sharing capabilities only as separately prioritized increments.

## Constraints, assumptions, and risks

### Locality

No meeting data may depend on an internet service. A chosen speech or language model could implicitly require downloads or network access. Sprint 2 must exercise a packaged or local model adapter with networking disabled.

### Local models

Transcription, diarization, and minutes use local adapters. Quality, latency, memory, storage, licenses, and hardware support may be inadequate. Sprint 2 must benchmark representative synthetic or approved fixtures and document resource use.

### Input formats

The MVP accepts only a small documented set of local formats. Media decoding may vary by codec and OS. Sprint 2 must define supported fixtures and rejection behavior.

### Attribution

Chair corrections are authoritative for the meeting record, but automated speaker segmentation can be inaccurate. Sprint 2 must test correction persistence and source traceability.

### Durable data

The source and derived record must remain local. Corruption or partial processing can make records inconsistent. Sprint 2 must test atomic local writes and recovery behavior.

### iOS portability

The shared core must not import macOS-only UI or capture APIs, but platform code could leak into domain logic. Sprint 2 must compile and test the core independently and review imports.

## Inception review checkpoint

The baseline is viable for an architecture-risk prototype, provided that Sprint
2 first decomposes PBI-011 into reviewable child PBIs from the accepted
architecture. Sprint 2 must validate local-model feasibility, the supported
input path, attribution correction persistence, source-linking, durable local
storage, and the CLI-to-review-player record-opening flow before a Construction
plan is authorized.
