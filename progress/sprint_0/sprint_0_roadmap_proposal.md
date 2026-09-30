# Sprint 0 — Tailored roadmap and Sprint 1 proposal

Status: Accepted

## Planning resolution

The bootstrap roadmap is broadly appropriate, but this proposal makes the
product's local-only boundary, macOS-first delivery, iOS portability, local AI,
live attribution, visual input, and UI/CLI cooperation explicit planning
drivers. Sprint 1 establishes a complete Inception baseline before architecture
validation: system view, stakeholders, actors, use cases, requirements,
backlog, initial release scope, risks, and candidate architecture. No model,
capture API, or storage architecture is selected before its requirements and
risks are evaluated.

## Proposed lifecycle roadmap

### Sprint 1 — Inception baseline

**Objective:** Confirm the accepted vision and intended outcomes; define the
system view and stakeholders; define actors, use cases, and success criteria;
define requirements; establish and prioritize the Product Backlog; define the
initial release scope, acceptance criteria, and exclusions; identify
constraints, assumptions, and risks; define a candidate architecture; then
review the Inception baseline for consistency and viability.

**PBI-003 — Define system view and stakeholders.** Define the system boundary,
context, and stakeholders for Meeting Summarizer.

**PBI-004 — Define actors, use cases, and success criteria.** Identify actors,
then define representative end-to-end use cases and success criteria for local
recording import, live screen capture, live transcript, operator-led speaker
naming, notes/actions, and cooperating UI/CLI use.

**PBI-005 — Define functional and non-functional requirements.** Define the
requirements needed to support the agreed use cases and success criteria.

**PBI-006 — Establish and prioritize the Product Backlog.** Establish and
prioritize product increments from the agreed requirements.

**PBI-007 — Define the initial release scope.** Select the smallest useful
macOS-first release from the prioritized backlog, with acceptance criteria and
explicit exclusions that preserve iOS portability and fully local operation.

**PBI-008 — Identify constraints, assumptions, and major risks.** Identify and
assess the constraints, assumptions, and major risks for fully local operation,
OS permissions, model feasibility, device resources, privacy, recording
formats, and portability.

**PBI-009 — Define candidate architecture.** Create a technology-neutral
candidate architecture for shared core, UI/CLI cooperation, local event
coordination, local AI responsibilities, capture, and durable local data.
Identify the architectural guidance needed to refine later prototype work
without inventing that work prematurely. Complete the project test profile with
the selected toolchain's exact build and test commands before Sprint 2 starts.

**PBI-010 — Review the Inception baseline for consistency and viability.** Make
a coherent milestone decision: proceed to architecture-risk validation, revise
the plan, or stop. Record the checkpoint requiring Sprint 2 to refine PBI-011
into independently reviewable work items from the accepted architecture.

**Completion evidence:** Product Owner accepts the system view, stakeholders,
actors, use cases, success criteria, requirements, backlog, initial release
scope, constraints, assumptions, risks, candidate architecture, and Inception
review as internally consistent, viable, and traceable to the accepted vision.

### Sprint 2 — Elaboration: validate critical local architecture risks

**Objective:** Reduce the risks that determine whether the MVP can deliver a
useful fully local experience on macOS while retaining a credible iOS path;
build and validate an executable architectural prototype; stabilize the
architecture baseline; and establish a Construction plan.

**PBI-011 — Build an executable architectural prototype.** Build a focused
prototype that exercises the selected MVP's architecturally significant paths
without claiming to be production implementation.

Before prototype construction, Sprint 2 setup/design refines PBI-011 into
independently reviewable `PBI-011.1`-style sub-PBIs using the accepted
candidate architecture. The Product Owner approves this decomposition before
prototype construction.

**PBI-012 — Validate critical technical assumptions and use cases.** Use the
prototype to gather evidence for the highest-risk local capture,
transcription, attribution, summarization/action, and UI/CLI-coordination
assumptions and use cases.

**PBI-013 — Refine use cases and supplementary requirements.** Refine use
cases and supplementary requirements when prototype evidence exposes gaps,
constraints, or changed assumptions.

**PBI-014 — Stabilize the architecture baseline.** Formulate and stabilize the
architecture baseline from prototype evidence.

**PBI-015 — Assess the Lifecycle Architecture milestone.** Decide whether the
stabilized architecture is ready for Construction. If it is not, state the
remaining Elaboration objective plainly.

**PBI-016 — Create the Construction plan.** Create the Construction plan from
the validation evidence, including the updated backlog, delivery order,
resource assumptions, and remaining risks.

**Completion evidence:** The Product Owner can see which assumptions were
validated, which remain, and whether Construction is justified.

### Later Construction and Transition planning

Only after the Lifecycle Architecture assessment should the plan schedule
production increments. Construction would deliver the approved MVP in thin,
locally testable slices. Transition would address packaging, privacy review,
stabilization, and user feedback; it is not implied by completion of an earlier
sprint.

## Proposed planning changes

On acceptance, replace the generic descriptions of PBI-003 through PBI-016 in
the root backlog and plan with the project-specific outcomes above. Preserve
Sprint 0's two accepted items and keep Sprint 1 and Sprint 2 in `Planned`
status. Do not create a code-bearing sprint or test profile until Sprint 1
evidence identifies the concrete architecture and validation needs.

## Traceability to the accepted vision

The initial release scope, risk assessment, candidate architecture, and
technical validation work in PBI-007 through PBI-012 preserve the fully local,
no-internet-service boundary.

PBI-007 through PBI-012 also keep macOS as the priority platform while testing
the credibility of the iOS path.

PBI-008, PBI-009, and PBI-012 address the feasibility, responsibilities, and
validation of local AI models and suitable OS services or public libraries.

PBI-004, PBI-005, and PBI-012 cover live attributed transcripts, operator
speaker naming, local recording import, and live screen capture. PBI-004,
PBI-009, and PBI-012 cover cooperating UI and CLI modes.

## Acceptance

The Product Owner accepted this tailored roadmap and Sprint 1 scope. The root `BACKLOG.md` and `PLAN.md` are the updated sources of truth.
