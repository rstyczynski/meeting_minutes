# Sprint 1 — Inception baseline design

## PBI-003 through PBI-010 — Inception baseline

Status: Accepted

### Design summary

The accepted Software Requirements Specification (SRS) is documented in
`docs/srs.md`. It defines the single-operator, local-only MVP: CLI import of a
local recording, offline timestamped transcript, chair-managed attribution
correction, and source-linked local minutes and actions. It explicitly defers
live capture, direct recording, visual attachments, alerts, search, export,
permanent deletion, and organization features.

`docs/architecture.md` records the accepted candidate architecture: Swift/SwiftUI,
a shared Swift Package core, a CLI executable, XCTest, local durable storage,
and local-model adapter contracts. `docs/test-profile.md` supplies the exact
proposed Sprint 2 build, smoke, unit, and integration commands.

### Feasibility and risks

The selected Swift/SwiftUI/SwiftPM direction is feasible for the shared core,
CLI, app UI, and XCTest structure. It preserves the iOS path by separating
macOS adapters from the core. It does not yet establish that any specific
local transcription, diarization, or minutes model meets the product's quality
and resource needs; that is Sprint 2's primary architectural validation.

### Testing Strategy

#### Recommended Sprint Parameters

- **Test:** none — Sprint 1 creates baseline documentation and no executable
  product or prototype.
- **Regression:** none — no executable product exists before Sprint 2.
- **Regression scope:** omitted.

#### Review targets

| Review target | Evidence |
|---|---|
| PBI-003 to PBI-005 | System boundary, stakeholders, use cases, requirements, and success criteria are complete and traceable. |
| PBI-006 to PBI-007 | Candidate backlog is ordered; MVP inclusions and exclusions match Product Owner decisions. |
| PBI-008 | Each significant constraint and risk has a mitigation or Sprint 2 validation path. |
| PBI-009 | Candidate boundaries preserve local-only operation and iOS portability; test profile contains exact commands. |
| PBI-010 | The review checkpoint is viable and requires PBI-011 child-item refinement before prototype construction. |

## Test Specification

Sprint Test Configuration:

- Test: none
- Regression: none
- Mode: managed

No automated test skeletons, component manifests, or new-test manifest are
applicable to this non-code iteration. Product Owner review of the proposed
Inception baseline is the required quality evidence. The proposed Sprint 2
commands are defined in `docs/test-profile.md`; they become executable evidence
only after the prototype package exists.

### Traceability

| Backlog item | Proposed evidence |
|---|---|
| PBI-003 | System view and stakeholders in `docs/srs.md` |
| PBI-004 | Use-case and success-criteria table in `docs/srs.md` |
| PBI-005 | Functional and non-functional requirements in `docs/srs.md` |
| PBI-006 | Candidate Product Backlog in `docs/srs.md` |
| PBI-007 | Initial release scope in `docs/srs.md` |
| PBI-008 | Constraints, assumptions, and risks table in `docs/srs.md` |
| PBI-009 | `docs/architecture.md` and `docs/test-profile.md` |
| PBI-010 | Inception review checkpoint in `docs/srs.md` |

## Design approval status

Accepted by the Product Owner on 2026-09-30.
