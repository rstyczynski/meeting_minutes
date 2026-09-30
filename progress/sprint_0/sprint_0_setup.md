# Sprint 0 — Setup: contract and analysis

Status: Complete

## Contract

### Project overview

Meeting Summarizer is a private, local-first companion for macOS and iOS. It
turns spoken and visual meetings into clear, attributable notes and follow-up
actions without sending meeting audio, video, transcripts, or metadata to the
internet.

### Active sprint and responsibilities

Sprint 0 is the sole sprint in `Progress`. Its work is limited to establishing
the product vision and deriving an initial, revisable project plan. I may create
and update the Sprint 0 evidence, vision, roadmap, backlog, and progress board;
I will not implement production code, select an irreversible technology stack,
or make external changes without Product Owner authorization.

### Rule compliance

Reviewed and will follow the project instructions, the local RUP adoption
patch, generic cooperation, Product Owner, Git, backlog, sprint, testing, test
failure, test migration, and bug-handling rules. Sprint 0 is non-code-bearing:
its `Test: none` and `Regression: none` settings mean that evidence is a
Product Owner review rather than manufactured automated tests. Managed-mode
approval is required at material decision points. Semantic commits are required;
the local patch requires a separate explicit Product Owner request before any
post-bootstrap push.

### Constraints and communication

The privacy boundary is a product constraint, not an aspiration: the product
must not transmit meeting audio, video, transcripts, or metadata to the
internet. Material scope or architecture changes will be proposed for Product
Owner acceptance. Product feedback and clarification requests, if needed, will
be recorded in the Sprint evidence without altering accepted text.

### Open questions

None block the vision. Decisions such as supported capture paths, speaker
attribution method, retention controls, export behavior, and the MVP boundary
belong to the upcoming Inception work rather than this vision sprint.

## Analysis

### PBI-001 — Establish the product vision

**Requirement summary:** Produce an accepted README that explains the intended
user value, problem, outcome, and constraints from the Product Owner's intent.

**Feasibility:** High. The supplied intent clearly identifies the audience,
outcome, trust requirement, platforms, and non-negotiable privacy boundary.

**Acceptance evidence:** Product Owner review of the proposed vision.

### PBI-002 — Derive the initial project plan from the vision

**Requirement summary:** After the vision is accepted, derive a prioritized,
outcome-oriented and revisable roadmap and a proposed next sprint.

**Feasibility:** High after PBI-001 approval. The roadmap must retain the
privacy constraint as a cross-cutting acceptance condition and explicitly mark
later technical choices as hypotheses to validate.

**Acceptance evidence:** Product Owner review of the tailored backlog and
Sprint 1 proposal, traceable to the accepted vision.

### Sprint assessment

The two items are tightly coupled, but managed mode requires an approval gate
between them: accept the vision before deriving the plan. No previous sprint
artifacts or production implementation exist, so there are no compatibility or
regression concerns. Construction and automated quality gates are not
applicable; the approved review evidence will replace them.

**Readiness for design:** Ready to propose the PBI-001 vision.
