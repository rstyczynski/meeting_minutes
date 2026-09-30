# Sprint 1 — Setup: contract and analysis

## Contract

### Scope and outcome

Sprint 1 is a non-code-bearing Inception iteration for Meeting Summarizer. It
must turn the accepted, local-only macOS-first vision into an internally
consistent baseline: system context, users and stakeholders, use cases,
requirements, ordered product increments, an initial-release boundary, risks,
and a candidate architecture. It must preserve a credible path to iOS.

### Working agreement

The active sprint is Sprint 1 in managed mode, with `Test: none` and
`Regression: none`. Automated test gates and production implementation are not
applicable in this iteration. Appropriate quality evidence is Product Owner
review of the Inception baseline and its traceability to the accepted vision.

I will work only on the Sprint 1 evidence and the progress board, preserve the
local-only privacy boundary, use only synthetic or approved local data in any
later validation, and ask for Product Owner approval at material decisions. I
will not select a production stack, change accepted scope, push remotely, or
start Sprint 2 without explicit authorization. The candidate architecture may
recommend a toolchain, but PBI-009 must leave no pending command in
`docs/test-profile.md` before Sprint 2 can start.

### Rules and constraints confirmed

The project instructions, local RUP patch, and applicable generic RUP rules
have been reviewed. They require: semantic local commits at phase boundaries;
no remote push without separate Product Owner authorization; backlog and plan
ownership by the Product Owner; append-only feedback and question records;
explicit design approval in managed mode; and traceability from each Sprint
item to review evidence. No technology-specific rule applies yet because no
implementation technology has been selected.

### Product Owner scope resolution

The first release is for a single local operator. It receives a user-supplied
local recording through a CLI argument, creates a local transcript with
meeting-chair-managed participant attribution and correction, and produces
local minutes and action items. Live screen capture, direct recording, visual
attachments, alerts, search, export, and permanent deletion are deferred.
The candidate toolchain direction is Swift/SwiftUI on macOS, a shared Swift
Package core, and XCTest; its detailed design remains subject to managed
approval.

## Analysis

### Context and compatibility

Sprint 0 accepted the product vision and the tailored lifecycle plan. No
production implementation, executable prototype, tests, or selected stack
exists, so there is no code compatibility constraint. The durable sources of
truth are `README.md`, `BACKLOG.md`, and `PLAN.md`; the retained materials in
`tmp/1.Inception/` are useful hypotheses only and do not change accepted scope.

### PBI-003 — System view and stakeholders

The system boundary is a local macOS application that accepts a
user-supplied local recording through CLI, turns it into a reviewable record,
and stores it locally. The primary actor is one local operator; the meeting
chair and participants are meeting-record roles. The device and OS are also
stakeholders. Team workflows beyond the local operator are deferred.

### PBI-004 — Actors, use cases, and success criteria

The core end-to-end path is: supply a local recording as a CLI argument;
create and review an offline timestamped transcript; let the meeting chair
associate neutral labels with participants and correct attribution; then create
and review local minutes and action items. UI/CLI cooperation remains an
architectural requirement, but command-line ingestion is the initial input
path. Success can be defined through offline processing, source-linked review,
and operator control.

### PBI-005 — Functional and non-functional requirements

Requirements can be organized around capture/import, transcript and speaker
correction, local summary/action extraction, reviewability, UI/CLI cooperation,
local durable data, privacy, performance, accessibility, reliability, and
portability. The absolute non-functional constraint is no transmission of
meeting audio, video, transcripts, or metadata to the internet. Requirements
for retention/deletion, export, encryption, model quality, device baseline,
and consent handling remain material open decisions.

### PBI-006 — Product Backlog

An ordered product backlog can be derived only after the initial-release
boundary is agreed. The preliminary ordering should prioritize an offline,
traceable meeting record and defer integrations, cloud synchronization,
organization administration, persistent facial identification, and automatic
cross-device synchronization. Additions from the retained MVP draft require
explicit acceptance before entering the Product Owner backlog.

### PBI-007 — Initial release scope

The smallest credible initial release is a local CLI ingestion flow from a
user-supplied recording through an offline timestamped, chair-correctable
record to reviewable minutes and action items. Live screen capture, direct
recording, visual attachment extraction, alerts, search, export, retention
controls, and permanent deletion are explicitly excluded from this release.

### PBI-008 — Constraints, assumptions, and risks

Known risks are macOS privacy permissions and capture limitations; local
transcription, diarization, and summarization quality and device resource use;
recording-format support; clear user consent; secure local retention; and
iOS-portable separation of platform code from shared capabilities. Each can be
assigned a validation experiment in Sprint 2 once the MVP and candidate
architecture are approved. No external service is feasible within the accepted
privacy boundary.

### PBI-009 — Candidate architecture

A candidate architecture can use a shared Swift Package core for meeting
records, timeline evidence, speaker labels, transcript, and minutes; a thin
SwiftUI macOS UI adapter; a local event boundary shared with the CLI; local
model adapters; and local durable storage. XCTest will supply the exact test
commands in `docs/test-profile.md`. The detailed design remains subject to
managed approval.

### PBI-010 — Inception baseline review

The baseline can be reviewed for traceability and viability after the preceding
decisions are approved. Its output must explicitly require Sprint 2 to refine
PBI-011 into bounded child items before constructing a prototype.

### Feasibility and readiness

The Inception work is feasible and has moderate uncertainty, concentrated in
local transcription, diarization, summarization quality, device resources,
privacy/consent behavior, and selected recording formats. The MVP boundary,
operator model, and toolchain direction are resolved. The Sprint is ready to
produce its managed design proposal.

### Review evidence for this non-code iteration

The approved quality approach is a structured Product Owner review of the
Inception baseline against PBI-003 through PBI-010. No test skeletons, test
manifests, automated gate logs, or implementation record will be manufactured
for this documentation-only iteration.
