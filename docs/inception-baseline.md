# Inception baseline — Meeting Summarizer

Status: Proposed

## System view and stakeholders

Meeting Summarizer is a local macOS application with a CLI ingestion path and
a SwiftUI review experience. It receives a recording already present on the
operator's device, creates an offline meeting record, and keeps the recording,
transcript, speaker labels, minutes, actions, and metadata on that device.
It does not call an internet service or synchronize meeting data.

| Stakeholder | Need | Influence on the baseline |
|---|---|---|
| Local operator | Produce and review a useful record without leaving the device | Starts imports, controls local data, and uses UI/CLI |
| Meeting chair | Make participant attribution trustworthy | Renames neutral labels and corrects transcript attribution |
| Meeting participant | Be represented accurately and with appropriate consent | May be named by the chair; no separate account is created |
| Follow-up owner | Understand a recorded action | Appears as action context, not as a system user in the MVP |
| macOS and its permissions | Protect user media and data | Constrain future capture and local storage behavior |

The initial release has no organization administrator, cloud service,
integration, participant account, or cross-device synchronization role.

## Actors, use cases, and success criteria

| Use case | Primary actor | Successful outcome |
|---|---|---|
| Import a recording | Local operator | A local audio/video recording is supplied as a CLI argument and becomes a local meeting record without network use. |
| Review the transcript | Local operator | The operator can follow time-ordered transcript segments against the local source recording. |
| Attribute speakers | Meeting chair | Neutral speaker labels can be renamed to participants and an incorrectly attributed segment can be corrected. |
| Review minutes and actions | Local operator | The operator can read locally generated summary, decisions, and action items with links to relevant transcript time ranges. |
| Coordinate UI and CLI | Local operator | A CLI import creates or updates a record that the local SwiftUI app can display after a defined local handoff. |

## Requirements

### Functional requirements

| ID | Requirement | Traceability |
|---|---|---|
| FR-01 | The CLI shall accept a local recording path as an import argument and reject nonexistent or unsupported input without copying data to a network service. | Import a recording |
| FR-02 | The system shall create a local meeting record containing source identity, timestamps, transcript segments, neutral speaker labels, minutes, decisions, actions, and source references. | All use cases |
| FR-03 | The system shall generate a timestamped local transcript from the imported recording through a replaceable local transcription adapter. | Review the transcript |
| FR-04 | The system shall assign neutral speaker labels and allow the meeting chair to rename labels and correct a segment's attribution. | Attribute speakers |
| FR-05 | The system shall generate local minutes containing a summary, decisions, action items, and open questions, with a source reference for each extracted item. | Review minutes and actions |
| FR-06 | The UI and CLI shall use the same local meeting-record contract; the UI shall detect a CLI-originated record through a local event/refresh boundary. | Coordinate UI and CLI |
| FR-07 | The system shall show operator-facing consent guidance before a future live-capture capability is enabled. | Privacy and future capture |

### Non-functional requirements

| ID | Requirement | Acceptance signal |
|---|---|---|
| NFR-01 | Meeting audio, video, transcripts, metadata, and derived records remain local and are not sent to the internet. | Offline fixture validation shows no network dependency; architecture review confirms no network client. |
| NFR-02 | Core meeting-domain code must not depend on SwiftUI, AppKit, or a capture API. | Core XCTest tests compile and run without the app target. |
| NFR-03 | Platform adapters must be replaceable so iOS can reuse core, local-model contracts, and record storage semantics. | Candidate architecture separates core from macOS adapters. |
| NFR-04 | The user can trace a transcript segment, decision, or action to a time range in the imported local recording. | Synthetic-fixture integration test verifies source references. |
| NFR-05 | Processing failures are explicit and preserve the source recording and already-completed local results. | Error-path tests verify no destructive overwrite. |

## Initial release scope

Included:

- A single local macOS operator.
- CLI import of a local recording using a positional or named input argument.
- Offline transcript creation with neutral labels.
- Chair-managed participant naming and attribution correction.
- Local minutes, decisions, action items, and open questions tied to source time ranges.
- A local SwiftUI review surface and defined UI/CLI handoff.

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
5. Present and refresh local meeting records in the SwiftUI review app.
6. Validate privacy, local-model feasibility, UI/CLI coordination, and iOS portability through an architectural prototype.
7. Add deferred capture, retention, search, export, and sharing capabilities only as separately prioritized increments.

## Constraints, assumptions, and risks

| Topic | Constraint or assumption | Risk | Sprint 2 validation |
|---|---|---|---|
| Locality | No meeting data may depend on an internet service. | A chosen speech or language model may implicitly require downloads or network access. | Exercise a packaged/local model adapter with network disabled. |
| Local models | Transcription, diarization, and minutes use local adapters. | Quality, latency, memory, storage, licenses, and hardware support may be inadequate. | Benchmark representative synthetic/approved fixtures and document resource use. |
| Input formats | The MVP accepts only a small documented set of local formats. | Media decoding may vary by codec and OS. | Define supported fixtures and rejection behavior. |
| Attribution | Chair corrections are authoritative for the meeting record. | Automated speaker segmentation can be inaccurate. | Test correction persistence and traceability. |
| Privacy and consent | The single operator receives consent guidance. | Meeting laws and policies differ by location and organization. | Keep guidance configurable and obtain legal/product review before live capture. |
| Durable data | The source and derived record must remain local. | Corruption or partial processing can make records inconsistent. | Test atomic local writes and recovery behavior. |
| iOS portability | The shared core must not import macOS-only UI or capture APIs. | Platform code can leak into domain logic. | Compile/test the core independently and review imports. |

## Inception review checkpoint

The baseline is viable for an architecture-risk prototype, provided that Sprint
2 first decomposes PBI-011 into reviewable child PBIs from the accepted
architecture. Sprint 2 must validate local-model feasibility, the supported
input path, attribution correction persistence, source-linking, durable local
storage, and UI/CLI handoff before a Construction plan is authorized.
