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
commands. Its introductory status and runner commands were reconciled during
Sprint 2 documentation review. No real meeting data may enter
source, fixtures, or logs. Sprint 2 is an architecture-risk prototype, not a
production release.

Open contracting questions: none. Ready for analysis.

## Analysis

This section records the initial analysis at Sprint 2 setup. Later Product
Owner decisions and construction status are tracked in the cross-sprint
impact section below and the implementation record.

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

## Replanning decision — 2026-10-01

The Product Owner identified that PBI-013 through PBI-016 depend on prototype
and benchmark results produced late in this iteration. The active Sprint 2
retains PBI-011 and PBI-012, including implementation of both configurable
transcription backends, the fixture generator, and their same-data benchmark.
PBI-013 through PBI-016 move to planned Sprint 3 so their acceptance decisions
can use the completed Sprint 2 evidence. PBI-012 may validate completed
prototype paths incrementally instead of waiting for the whole prototype.
The earlier analysis of PBI-013 through PBI-016 above records the initial
scope; their execution now belongs to Sprint 3.

## Replanning correction — 2026-10-01

The Product Owner clarified that PBI-012 is the broader validation item and
belongs with PBI-013 through PBI-016 in Sprint 3. Sprint 2 keeps the
same-data FluidAudio and whisper.cpp benchmark as acceptance evidence for
PBI-011.5. The earlier analysis and replanning note record the evolving
scope; the current assignments are those in `PLAN.md`.

## Benchmark item decision — 2026-10-01

The Product Owner made benchmarking an independent Product Backlog item,
PBI-018, assigned to Sprint 2. It compares technical options using shared
test data and documented measures, including the FluidAudio and whisper.cpp
comparison requested for this sprint. PBI-011 supplies the executable
prototype; Sprint 3 PBI-012 uses its benchmark evidence for broader validation.
The earlier notes about placing the benchmark within PBI-011.5 record the
superseded proposal.

## Cross-sprint requirements impact — 2026-10-01

During Sprint 2, the Product Owner refined the CLI workflow to three
independently invoked capabilities: transcribe, optional recognize, and
optional summarize. A summary may use neutral speaker labels when no names
have been assigned. The Product Owner also requested optional automatic
speaker-name suggestions from local evidence as a nice-to-have functional
requirement beyond the initial MVP. These decisions revised the durable
Sprint 1 SRS in docs/srs.md, particularly FR-01, FR-02, FR-04, FR-05,
FR-07, FR-08, the use cases, and release scope. The SRS is a shared
project artifact, not a Sprint 2-only document.

The Product Owner subsequently added FR-09 and FR-10 for low-quality meeting
audio, including participant-level detection or warning when possible,
original preservation, review, and comparison of any alternate input. These
have corresponding use cases in the SRS. The requirements are critical to
validate in Sprint 2 against the approved
ES2002a meeting's documented headset problem. It is another change to the
Sprint 1 SRS baseline and must be included in the cross-sprint review.

This change triggers a cross-sprint baseline review. Sprint 1 PBI-004
(use cases), PBI-005 (SRS), PBI-009 (candidate architecture), and PBI-010
(Inception consistency review) may no longer be fully supported by their
original evidence. The architecture's single-import flow and the Sprint 2
accepted design must be reconciled with the revised SRS. The test profile
must also be checked against the new commands. If review finds that an
earlier acceptance result is invalid, record a targeted redo or replacement
as new backlog and sprint work through the Product Owner's process. Do not
silently rewrite Sprint 1 history or change its Done status. Sprint 3's
PBI-012 through PBI-014 provide a planned evidence-based review point,
subject to Product Owner prioritization if extra redo work is required.
The Product Owner accepted the revised Sprint 2 CLI design on 2026-10-01.
The commands have since been implemented and their exercised behavior is
recorded in the implementation and functional test records. A targeted
Sprint 1 baseline review remains for the later evidence-based iteration.
Sprint 2 validates the separability and feasibility of the three
capabilities; detailed dependency and stale-derived-content rules belong
to later requirements refinement, not this architecture-risk benchmark.
