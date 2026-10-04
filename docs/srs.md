# Software Requirements Specification — Meeting Summarizer

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

### Transcribe a recording

The local operator supplies a local audio or video recording as a CLI argument.
It becomes a local meeting record with a timestamped transcript, without
network use or automatic generation of minutes. A UI file picker is not
required for the MVP. The operator may request English, Polish, or automatic
language selection for transcription; the saved record shows the request and
the selected local ASR model. An incompatible English-only model must fail
clearly without replacing an earlier record. Automatic selection does not
promise recognition of language switches within a recording.

### Review the transcript

The local operator follows time-ordered transcript segments against the local
source recording. The review player can seek the local recording to a selected
segment's timestamp.

### Attribute speakers

The local operator, acting as meeting chair, may rename neutral speaker labels
to participants and correct an incorrectly attributed segment after reviewing
the corresponding local media at its timestamp. This step is optional. If it
is skipped, a requested meeting summary uses neutral speaker labels.

### Find a participant affected by poor audio

After transcription, the local operator reviews quality warnings. When one
participant's recording is weak or noisy, the system links suspect time
ranges to that participant's neutral speaker ID if the audio supports a
reliable attribution. The operator can seek to the original recording and
decide whether to correct transcript words or speaker attribution. If the
system cannot determine which speaker is affected, it shows the suspect
time range without naming anyone. Success means the operator can locate and
review the affected speech without treating uncertain attribution as fact.

### Review and recover low-quality audio

When the system finds audio that may undermine transcription or attribution,
the local operator sees which parts of the record need attention and can
replay the unchanged original. If a local enhancement or alternate recording
is available, the operator may compare a new transcript with the original
result and choose which version to use. A failed or unhelpful recovery keeps
the original source and previous local result available. Success means poor
audio is visible, reviewable, and never silently presented as reliable text.

### Review minutes and actions

When requested, the system generates a summary, decisions, and action items
from the saved transcript, using chair-assigned names where available and
neutral speaker labels elsewhere. The local operator reads the result with
links to relevant transcript time ranges. Transcription does not
automatically trigger this step.

Before presenting a complete minutes draft, the operator can inspect a
corrected reading layer derived from the saved transcript. The original ASR
segments remain available. The draft organizes substantive utterances by
topic and shows any unresolved correction or topic-coverage gap.

### Coordinate UI and CLI

The CLI and review player use the same local meeting-record store. After
transcription, the CLI prints a local record identifier; the operator opens
that record in the review player. The CLI separately controls recognition and
summary. No background application, event subscription, or automatic
cross-process refresh is required.

## Requirements

### Functional requirements

#### FR-01 — Transcribe local recording

The CLI shall accept a local recording path for a transcribe command and
reject nonexistent or unsupported input without copying data to a network
service.

#### FR-02 — Create local meeting record

The system shall create a local meeting record containing source identity,
timestamps, transcript segments, neutral speaker labels, and source
references. Minutes, decisions, and actions are added only if summary is
requested.

#### FR-03 — Generate transcript

The system shall generate a timestamped local transcript from the imported
recording through a replaceable local transcription adapter.

#### FR-04 — Correct speaker attribution

The system shall assign neutral speaker labels and allow the meeting chair to
rename labels and correct a segment's attribution through an optional
recognize step. Chair assignments are authoritative. If recognize is skipped,
the record and any summary retain neutral speaker labels.

#### FR-05 — Generate source-linked minutes

When requested through a separate summarize command, the system shall
generate local minutes containing a summary, decisions, action items, and open
questions from the saved transcript. It shall use assigned speaker names when
available and otherwise retain neutral labels; it shall not invent a person's
identity or transcribe the media again. It may retain and show source
references for an operator's review, but those references are optional and
are not part of the participant-facing minutes delivery.

The system shall prepare a reviewable correction layer without overwriting
the raw timed transcript. It shall examine each isolated-token or short
speaker-split candidate against both neighboring fragments and retain the
source IDs, timestamps, original speaker labels, correction, reason, and
review status. It shall not discard a word merely because it is short or
unassigned. A suspected audio/ASR artifact can be excluded from the
minutes input only with recorded evidence or operator review; unresolved
cases remain visible.

The reading-layer segmentation and neighbor-join parameters shall be
configurable through a documented profile shared by CLI inspection, operator
review and multi-stage minutes preparation. The saved record shall retain
the resolved profile. Default grouping shall preserve explicit speaker changes. A gap at least
the configurable positive `longSilenceBoundarySeconds` threshold shall start
a new segment even when the speaker label is unchanged. Its prototype
default is 10 seconds; shorter pauses remain joinable, and no elapsed-duration
cap applies by default. This temporal boundary does not assert a change of
topic; semantic continuity remains a separate validation concern.
A changed profile shall preserve source parts and operator corrections and
invalidate dependent minutes. Existing diarization labels provide boundary
evidence; semantic continuity and independent acoustic checks of uncertain
joins remain validation work identified by the prototype.

For a complete minutes draft, the system shall identify meeting topics and
assign every substantive utterance to one or more topics. It shall account
for every raw text-bearing segment in a corrected utterance or an explicitly
reviewed artifact record. Any unresolved correction or unassigned
substantive utterance prevents presentation of the result as complete
minutes. The detailed method and tests are in the accepted Sprint 2 design;
real-meeting quality is still under validation.

#### FR-06 — Share local records between CLI and review player

The CLI and review player shall use the same local meeting-record contract and
store. The CLI shall print the created record identifier, and the review player
shall open a record by that identifier. No background application, event
subscription, or automatic refresh is required.

Operator review shall expose a full-recording audio-position slider and
current time/duration, including in the selected-text correction view.
Seeking shall pause and cancel bounded fragment playback; the operator
explicitly resumes from the selected position. The Product Owner directed
this refinement during Sprint 2 after a long same-speaker silence was hidden
inside one reading segment.

Audio playback and slider movement shall highlight the corresponding timed
transcript text and follow it into view. A position without a timed source
part shall highlight no text, including silence inside a corrected range.
Selecting a nonempty continuous text fragment in one reading turn shall pause
and seek to its earliest mapped source start; explicit Play resumes.
Playback highlighting shall remain independent of the selection used for
correction. Precision shall follow available source timestamps: a multiword
source part or saved range replacement is highlighted as a whole mapped
span, without invented replacement-word times. The Product Owner accepted
this bidirectional synchronization during Sprint 2.

#### FR-07 — Independent CLI capabilities

The CLI shall expose transcribe, recognize, and summarize as separately
invoked capabilities. A transcript-only record is valid. Recognize and
summarize are independent optional operations after transcription. Summarize
shall run with neutral speaker labels when recognize has not assigned names.
Detailed rules for changes made after a summary, reruns, and stale derived
content will be defined from validation evidence in a later iteration.

#### FR-08 — Optional automatic speaker-name suggestions

As a nice-to-have capability beyond the initial MVP, recognize may suggest
speaker names from local evidence, including spoken introductions in the
meeting media and, if the operator supplies them, local voice references or
other local meeting context. Suggestions must identify their evidence and
uncertainty, remain editable by the chair, and never become confirmed names
without chair review. The system must work without this capability through
manual name assignment. Automatic diarization labels alone are not a person's
identity.

#### FR-09 — Identify a participant affected by low-quality audio

The system shall identify time ranges whose audio quality may make
transcription or speaker attribution unreliable. When it can determine the
affected speaker, it shall flag that neutral speaker ID and the relevant
source ranges for operator review. When it cannot, it shall flag the
recording or ranges without inventing an identity. The warning shall state
the uncertainty and shall not present unreliable words or attribution as
confirmed. Sprint 2 shall validate this requirement against a reference
participant with a documented microphone problem.

#### FR-10 — Preserve and review low-quality audio

The system shall preserve the original recording and make each suspect range
replayable for operator review. If local enhancement or an alternate input
is offered, the operator shall be able to compare its derived result with the
original result, retain provenance, and keep the prior local result if
recovery fails or does not help. Sprint 2 shall measure whether the proposed
local recovery path improves or harms transcription and attribution; exact
quality thresholds and production recovery policy will be defined from that
evidence.

#### FR-11 — Recognition languages

The system shall support speech recognition and transcription in English and
Polish. Both languages are required. Sprint 2 shall prototype explicit
language control for transcription and validate local ASR on referenced
English and Polish speech. The current English-only model measurements do
not satisfy this requirement. Mixed-language behavior and production quality
thresholds will be refined from the new evidence in a later iteration.

### Non-functional requirements

#### NFR-01 — Local-only data

Meeting audio, video, transcripts, metadata, and derived records remain local and are not sent to the internet. Offline fixture validation must show no network dependency, and architecture review must confirm no network client.

#### NFR-02 — Portable core

Core meeting-domain code must not depend on SwiftUI, AppKit, or a capture API. Core Swift tests must compile and run without the app target.

#### NFR-03 — Replaceable platform adapters

Platform adapters must be replaceable so iOS can reuse core, local-model contracts, and record-storage semantics. The candidate architecture must keep the core separate from macOS adapters.

#### NFR-04 — Source traceability

When an operator chooses review mode, the system can trace a transcript segment, decision, or action to a time range in the imported local recording. Participant-facing minutes must remain understandable without source references. A synthetic-fixture integration test must verify source references when present.

#### NFR-05 — Non-destructive failure handling

Processing failures are explicit and preserve the source recording and already-completed local results. Error-path tests must verify that no destructive overwrite occurs.

#### NFR-06 — Validate model responses before downstream use

Every model-backed step shall validate its response before storing it or
passing it to another product step. Technical checks cover a complete
parseable response, the required schema and types, bounded output size,
and references to existing source data. Content checks must establish
that saved claims are supported by their cited source and appropriate for
their item type; valid JSON alone is insufficient. A failed technical
check may be returned to the model with a concrete repair request, but
retries must be bounded. If validation still fails, the product shall
report the reason, withhold the unvalidated result, and preserve the last
valid meeting record. This requirement was added during Sprint 2 after
real-meeting minutes experiments exposed unsupported claims and truncated
model output. The Sprint 2 minutes adapter is its first implementation;
later model-backed capabilities must apply the same boundary.

## Initial release scope

Included:

- A single local macOS operator.
- CLI transcription of a local recording using a positional or named input argument.
- Offline transcript creation with neutral labels.
- Detection and review flags for audio regions or participants whose recording
  quality undermines transcription or attribution.
- Optional chair-managed participant naming and attribution correction.
- Optional, separately invoked local minutes, decisions, action items, and
  open questions, using assigned names when available and neutral labels
  otherwise; source references are available only for operator review.
- A local SwiftUI review player that opens a CLI-created local record and
  synchronizes transcript selection with local-media seeking.

Excluded:

- Live screen capture and direct recording.
- Visual attachment extraction.
- Alerts, search, export, permanent deletion, automatic sharing, and cloud sync.
- Participant accounts, organization administration, and policy management.
- Persistent facial identification.
- Automatic speaker-name discovery from media or local voice references
  (FR-08); manual assignment remains in the MVP.

## Candidate Product Backlog

This is a proposed Product Owner backlog ordering; it does not amend the root
backlog until accepted.

1. Import a local recording into a durable local meeting record.
2. Create an offline timestamped transcript through a local-model adapter.
3. Support optional chair-managed speaker naming and attribution correction.
4. Generate source-linked local minutes, decisions, actions, and open questions
   only when requested, with or without prior speaker-name assignment.
5. Open and review a local meeting record by its CLI-created identifier in the SwiftUI review player.
6. Validate privacy, local-model feasibility, record-opening flow, and iOS portability through an architectural prototype.
7. Add deferred capture, retention, search, export, and sharing capabilities only as separately prioritized increments.
8. Consider optional automatic speaker-name suggestions under FR-08 only as a
   separately prioritized increment.

## Constraints, assumptions, and risks

### Locality

No meeting data may depend on an internet service. A chosen speech or language model could implicitly require downloads or network access. Sprint 2 must exercise a packaged or local model adapter with networking disabled.

### Local models

Transcription, diarization, and minutes use local adapters. Quality, latency, memory, storage, licenses, and hardware support may be inadequate. Sprint 2 must benchmark representative synthetic or approved fixtures and document resource use.

### Input formats

The MVP accepts only a small documented set of local formats. Media decoding may vary by codec and OS. Sprint 2 must define supported fixtures and rejection behavior.

### Attribution

Chair corrections are authoritative for the meeting record, but automated speaker segmentation can be inaccurate. Sprint 2 must test correction persistence and source traceability.

### Low-quality participant audio

A participant's microphone may be distant, missing, or noisy while other
voices remain clear. Sprint 2 must test whether the candidate local pipeline
detects the affected participant or time ranges, measure transcription and
attribution quality separately for that participant when reference data
allows, and report whether local preprocessing helps or harms the result.
The system must preserve and make reviewable the original audio.

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
