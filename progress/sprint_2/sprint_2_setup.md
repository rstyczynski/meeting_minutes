# Sprint 2 — Contract and analysis

## Contract

Sprint 2 is the sole active sprint. It runs in managed mode with smoke, unit,
and integration checks for new work and regression. The Sprint 1 contracting
review established the cooperation rules; this setup rechecks the current
plan, backlog, accepted SRS, candidate architecture, test profile, and Sprint 1
review evidence. The local RUP patch governs the Elaboration profile and
requires PBI-011 child items and Product Owner approval before prototype
construction.

The implementor may create current-sprint design, prototype, tests, and
evidence. Changes to Product Owner priorities or sprint assignments require
the backlog and sprint procedures. Only assigned items appear on the progress
board. No remote push is authorized by this sprint request.

The accepted test profile names exact Swift build, smoke, unit, and integration
commands. Its introductory template wording is stale, but its command fields
are filled and Sprint 1 review accepted them. No real meeting data may enter
source, fixtures, or logs. Sprint 2 is an architecture-risk prototype, not a
production release.

Open contracting questions: none. Ready for analysis.

## Analysis

The accepted MVP imports an existing local recording through the CLI, creates
a timestamped offline meeting record, allows chair correction of neutral
speaker labels, produces source-linked minutes and actions, and opens the
CLI-created record in a local SwiftUI review player. Live capture, alerts,
visual extraction, and cloud services are outside this sprint. There is no
product code yet; Swift 6.3.3 is installed on the working Mac.

### PBI-011 — Prototype

Build an executable Swift prototype of the shared core, CLI import, local
store, model-adapter boundaries, correction flow, and record opening. Split
this parent into bounded child items in the design and demonstrate each path.
The accepted SRS and architecture are its prerequisites; Product Owner
approval of the decomposition precedes construction.

### PBI-012 — Validation

Run offline experiments on local transcription, diarization, and minutes
generation, plus supported media, resource use, source links, persistence,
and UI/CLI coordination. Record results or explicitly named remaining risks.
This work depends on the PBI-011 paths and synthetic or approved fixtures.

### PBI-013 — Requirements

Amend use cases and supplementary requirements only where PBI-012 evidence
changes an assumption or exposes a gap.

### PBI-014 — Architecture

Record which component boundaries and model choices are supported by PBI-012
and PBI-013 evidence and what remains provisional.

### PBI-015 — Milestone

Assess the Lifecycle Architecture milestone against measured evidence from
PBI-014. Identify further Elaboration work if the architecture is not ready.

### PBI-016 — Construction plan

Propose delivery order, resource assumptions, quality gates, and unresolved
risks from the milestone assessment. Material plan changes require Product
Owner acceptance.

The architecture deliberately leaves transcription, diarization, and language
model implementations unselected. A deterministic adapter can verify the
contracts and record flow, but cannot establish real-model quality, latency,
license, packaging, or memory feasibility. PBI-012 must report those results
separately. Sprint scope follows the accepted SRS, architecture, and plan.

The prototype is feasible as a bounded Swift Package experiment. The main
uncertainty is obtaining and evaluating suitable fully local models and
representative permitted fixtures, not the basic package or store structure.
The design must state candidate-selection criteria, observable measures,
fallback if an experiment cannot run, and a production-retention decision.

Open analysis questions: none blocks design. Product Owner review is required
for the proposed PBI-011 breakdown and design before construction.

Readiness: ready for design.
