# RUP Patch — Method Adoption and Iteration Semantics

This is an optional local wrapper over the canonical RUP Strikes Back method in the `RUPStrikesBack` submodule. A project may use RUP Strikes Back without this directory. When this wrapper is present, its policies refine or override the generic method only where stated below.

## P0. Include RUP Strikes Back as a controlled project method

The project adopts RUP Strikes Back through the `RUPStrikesBack` Git submodule, tracked on the selected method branch and pinned by this repository’s Git submodule revision. The submodule is the source for the generic manager, phase-agent procedures, sprint/backlog formats, and generic rules.

The project root contains the local adoption layer:

1. `.gitmodules` registers the RUP Strikes Back submodule and selected branch.
2. `AGENTS.md` tells Codex where the method is and when to use it.
3. `RUPStrikesBack.patch/RUP_patch.md` records project-specific method refinements and overrides; the root `RUP_patch.md` is its compatibility entry point.
4. `.agents/skills/rup-strikes-back/` is the Codex cycle entry point, while `rup-backlog`, `rup-sprint`, and `rup-progress` are mandatory artifact adapters. Their references map to the canonical manager, command, and phase procedures in the submodule.
5. `BACKLOG.md` holds Product Owner priorities and backlog-item acceptance signals.
6. `PLAN.md` holds RUP Strikes Back sprint definitions, statuses, modes, and quality expectations.

Do not copy the submodule’s `AGENTS.md`, `HUMANS.md`, `RUP_patch.md`, or Claude command files into the project root. The local `AGENTS.md`, this patch, and the Codex skill provide the project-specific integration layer. The submodule remains the canonical generic agentic method; Codex adapters provide host-specific invocation and apply local refinements.

Update the submodule only through an explicit Product Owner request. Before adopting an update, review the changed method rules, confirm that this patch and the Codex wrapper still apply, and commit the resulting submodule revision together with any required local changes. Do not update the method during an active sprint unless the Product Owner explicitly treats it as a process change.

## P0.0. Establish the Git baseline during bootstrap

Bootstrap validates that the project is a Git repository and has an `origin` remote. If Git is absent, bootstrap initializes the repository and uses `main` as its default branch. If `origin` is absent, bootstrap creates a private repository on GitHub.com using the authenticated GitHub account, names it after the project directory, and configures it as `origin`. An existing origin is preserved; bootstrap does not rewrite it or force-push.

After installing only the method and generic-bootstrap artifacts, bootstrap creates one semantic baseline commit and pushes the current branch to `origin`. This authorization applies to the bootstrap flow itself. Subsequent remote repositories, remote changes, and pushes still require an explicit Product Owner request.

## P0.1. Initialize process artifacts when needed

`BACKLOG.md` and `PLAN.md` are created before the first sprint. Progress artifacts, including `PROGRESS_BOARD.md` and sprint-specific records under `progress/`, are created and maintained by the RUP Strikes Back cycle when a sprint starts; do not create placeholder progress files in advance.

Before the first code-bearing sprint, define the project’s test profile in this patch or a referenced project rule. The project uses `docs/test-profile.md` for this purpose. It must map the generic test and regression fields to the actual project’s build, smoke-test, unit-test, integration-test, and applicable operational-validation commands. Do not claim that the submodule’s sample shell-test commands apply to the project. A test-profile template does not satisfy this gate: PBI-009 must replace its pending command fields with the candidate architecture's actual commands before Sprint 2 starts.

## P0.2. Generic artifacts bootstrap Sprint 0

`RUPStrikesBack.patch/bootstrap/` contains reusable RUP roadmap, backlog, sprint-plan, and test-profile templates, a generic `AGENTS.md`, and Codex skill adapters. `RUPStrikesBack.patch/BOOTSTRAP_PROMPT.md` is the operator-only bootstrap prompt and is deliberately kept outside the overlay. These artifacts are inputs to Sprint 0 only; they are not product requirements or active product backlog items. The bootstrap plan preselects Sprint 0 with `Status: Progress`, but execution still requires an explicit Product Owner request.

At project initialization, overlay the complete contents of `RUPStrikesBack.patch/bootstrap/` onto the project root, including hidden directories. Do not copy `RUPStrikesBack.patch/BOOTSTRAP_PROMPT.md` into the project root. The Product Owner explicitly requests execution of the preselected Sprint 0 and supplies the initial product intent through the working conversation. PBI-001 creates and accepts the project `README.md` as the vision product. Sprint 0 then derives this project’s real roadmap and proposes the next sprint from that vision. The generic later-sprint entries are initial hypotheses: Sprint 0 or subsequent iterations may retain, refine, split, reorder, or replace them. After Sprint 0, the root project artifacts—not the generic templates—are the sources of truth for the project’s scope and delivery work.

The generic bootstrap is deliberately tailored over its first three iterations. Sprint 0 proposes an initial lifecycle and iteration plan from the vision. Sprint 1 tests and refines that plan against business context, requirements, scope, risks, and an initial architecture. Sprint 2 refines it again from technical-validation evidence and the Lifecycle Architecture assessment. In each of these iterations, the agent must propose additions, removals, mergers, splits, reordered work, or a simpler path when the project’s size, uncertainty, existing assets, constraints, or risk profile justify it. In managed mode, the Product Owner accepts each material plan change. The plan must record the decision and rationale; generic tasks are defaults, never mandatory ceremony.

## P0.3. Place project artifacts by lifecycle role

The root `README.md` holds the accepted product vision and project orientation. `docs/` holds durable shared project deliverables created and accepted during sprints, such as requirements, architecture, decisions, and operating documentation.

`progress/sprint_N/` holds the evidence and review artifacts for one sprint. `tmp/` holds provisional material retained only for reference; it is not a source of truth and must be recreated in `docs/` or another approved location when a sprint formally delivers it. `RUPStrikesBack.patch/bootstrap/` remains the reusable bootstrap input described above.

## P0.4. Anchor progress-board items to an assigned sprint

`PROGRESS_BOARD.md` follows the canonical four-column form and tracks both a
sprint's real-time status and the real-time statuses of backlog items assigned
to that sprint. Every backlog-item row must name the Sprint that contains the
item in `PLAN.md`; an unscheduled item never receives a standalone progress
board row.

A Product Owner may promote an accepted review or feedback proposal into the
root backlog with `Status: Proposed`. It remains there, without a progress
board row, until the Product Owner prioritizes and assigns it to a named Sprint
in `PLAN.md`. The sprint procedure then creates its board row. This refines the
canonical `/backlog add` instruction only for unscheduled proposals.

## P1. Apply the RUP Strikes Back cycle proportionately

The Codex RUP Strikes Back manager's complete contracting, analysis/design, construction, quality-validation, and wrap-up pipeline is primarily a code-bearing Construction-iteration workflow. It should run fully when a sprint creates or materially changes production code.

Sprint 0 and Inception iterations use the same collaboration discipline, but produce vision, requirements, plans, risk evidence, and reviews rather than forcing implementation. An Elaboration iteration may construct a prototype and run technical tests when that is needed to retire risk, but it need not produce a production feature. In non-code-bearing iterations, construction and automated-test gates may be not applicable; the plan and sprint evidence must state the reason and define the appropriate review or experiment instead.

This is not a waterfall handoff. Every iteration consciously considers the relevant RUP disciplines, at a depth proportional to its purpose, risk, and lifecycle phase. The RUP Strikes Back workflow inside an iteration does not itself advance the product from one project-level RUP phase to the next.

## P1.1. Use progressive plan refinement as a first-class outcome

The plan is an evolving project artifact, not a one-time bootstrap output. Sprint 0 creates the initial project plan. Sprint 1 establishes or revises the Inception plan and evaluates the Lifecycle Objectives decision. Sprint 2 establishes or revises the Construction plan from technical evidence and evaluates the Lifecycle Architecture decision. Later iterations continue to refine scope, risks, ordering, quality expectations, and release plans when evidence requires it.

## P1.2. Materialize durable Inception requirements and architecture artifacts

When an Inception iteration establishes the initial requirements, PBI-005
materializes `docs/srs.md` as the Software Requirements Specification (SRS).
It records the accepted system boundary, stakeholders, use cases and success
criteria, functional and non-functional requirements, initial release scope,
constraints, assumptions, and risks needed to guide the next iteration.

PBI-009 materializes `docs/architecture.md` as the accepted candidate
architecture. It explains how the proposed architecture supports the SRS,
identifies the assumptions requiring Elaboration validation, and defines the
project's concrete test-profile commands before a code-bearing iteration
starts. An accepted candidate architecture is an accepted direction for
validation, not evidence that its technical risks have been retired.

These artifacts are created from the accepted project vision during Inception;
they are not blank bootstrap templates. Later iterations refine them when
validation evidence or product decisions change their content. The Inception
review evaluates them together with the Product Backlog and test profile.

## P2. Project lifecycle phases set emphasis; they do not prohibit refinement

The project lifecycle remains Inception, Elaboration, Construction, and Transition. These phases establish the dominant emphasis of the work:

- Inception emphasizes business context, vision, requirements, scope, and major risks.
- Elaboration emphasizes architecture, risk retirement, design, and validation.
- Construction emphasizes implementation and testing.
- Transition emphasizes deployment, stabilization, and user feedback.

All disciplines remain open to refinement in later iterations. In particular, business modeling and requirements are mostly established early, but evidence from design, implementation, testing, or use may require them to be revisited.

## P3. Sprint wrap-up is not necessarily project Transition

The RUP Strikes Back wrap-up phase completes and documents a sprint. It does not by itself mean that the product has entered the project-level Transition phase or is ready for release. Project-level Transition occurs when the project plan declares release, deployment, and adoption activities to be the dominant focus.

## P4. A sprint may deliver multiple coherent outcomes

A sprint may contain multiple independently coherent backlog items when they share a common iteration objective, have manageable dependencies, and can be reviewed together. This is particularly appropriate for Inception and Elaboration, where one iteration can establish several connected artifacts such as requirements, risks, scope, and an architecture baseline.

Each backlog item must retain its own value statement and acceptance signal. The sprint design and wrap-up must identify the evidence for each item, so grouping does not hide incomplete work or weaken traceability. Split items into separate sprints when their dependencies, risk, approval needs, or validation methods would make a single review unclear.

## P5. Process entry point and local method adoption

The project root `BACKLOG.md` is the source of Product Owner priorities. The project root `PLAN.md` is the source of sprint selection and status. When installed, the root `RUP_patch.md` points to `RUPStrikesBack.patch/RUP_patch.md`, which defines local policy that supplements or overrides the generic method in the `RUPStrikesBack` submodule.

Sprint 0 is marked `Progress` by the bootstrap plan. To execute it, the Product Owner explicitly invokes the Codex `rup-strikes-back` skill in the declared mode. For a later planned sprint, the Product Owner first changes that sprint’s status in the root `PLAN.md` from `Planned` to `Progress`, then explicitly invokes the skill. The agent reads its manager and selected phase procedures from `.agents/skills/rup-strikes-back/references/`, then applies this local patch before executing the sprint.

`rup-strikes-back` is the Codex method entry point. The submodule's `/rup-manager` is a Claude compatibility command, not a native Codex command. Managed mode remains the default: the agent pauses for Product Owner approval at the defined decision points.

## P6. Refine prototype work into hierarchical sub-PBIs

When an accepted Inception architecture identifies a prototype PBI that spans
several independently reviewable pieces of work, the following Elaboration
iteration must refine that parent PBI before prototype construction. This is a
required planning checkpoint, not permission to invent the work during
Inception.

Use hierarchical identifiers in the form `PBI-XX.YY`, where `PBI-XX` is the
accepted parent PBI and `YY` is a sequential child number. For example,
`PBI-011.1`, `PBI-011.2`, and `PBI-011.3` are child work items of `PBI-011`.

Create the child items during the Elaboration sprint's setup/design phase, in
the active sprint's design record. Each child item must state its parent, its
bounded outcome, its acceptance evidence, and its dependency on other child
items. Record the same identifiers on the progress board for status tracking.

Child sub-PBIs are sprint-scoped refinements of their parent, not new
Product-Owner backlog items. Keep the parent PBI in the root `BACKLOG.md` and
`PLAN.md`; promote a child to a new root backlog item only when it gains
independent product value, priority, or deferral authority. In managed mode,
the Product Owner approves the proposed decomposition before prototype
construction starts.

## P7. Read the separate Product Owner preferences file

`RUPStrikesBack.patch/USER_PREFERENCES.md` is this project's plain Markdown
customization file for durable preferences explicitly stated by the Product
Owner. Read it alongside this patch before drafting new or revised
project-authored narrative artifacts or a sprint review. The Product Owner
may amend it through an explicit request; do not infer durable preferences
from incidental conversation. A preference does not change a mandatory
method-defined artifact structure unless the Product Owner explicitly asks
for that process change.

## P8. Reconcile documentation and verify before each commit

Work may use multiple edits while completing one increment. An increment is
an assigned PBI or a sprint-tracked child PBI with its own completion
evidence. Do not commit after each file change or merely because a phase has
advanced. After each increment is complete, reconcile its code, tests, and
documentation as one unit. Before committing it, create or update the active
sprint's documentation audit under `progress/sprint_N/`. The audit must check
the root SRS, architecture, test profile, sprint setup, accepted design and
test specification, implementation record, functional test record, README,
and progress board against the latest Product Owner decisions and actual
executable behavior. Record each checked artifact, the evidence inspected,
corrections made, and any unresolved approval or implementation dependency.
Check copy-paste commands and expected output against real execution before
calling them working examples. Label proposed commands and unrun tests as
pending. Keep the required progress-board table, but follow
`USER_PREFERENCES.md` for narrative documents.

Run the applicable build, tests, experiments, syntax or link checks, and
`git diff --check` before the commit. Record the exact checks and their
results in the sprint evidence. A failed check or unresolved material design
approval blocks that PBI's completion commit. Stage and commit the completed
increment's implementation, tests, documentation, and audit evidence
together. Its Git commit is the durable completion marker; identify that
commit in the next audit or sprint wrap-up. Work shared by multiple PBIs
must be attributed in the audit and included with the first completed
increment that depends on it, without claiming later PBIs are complete.
This local commit rule does not authorize a remote push.

The audit is a pre-commit and pre-advance control, not the canonical Phase 5
documentation wrap-up. A failed or incomplete audit blocks the affected next
step; it does not change a sprint or backlog-item status by itself. In
managed mode, a material design change still requires Product Owner approval
before its code or test skeletons are implemented. Record the approval and
re-run the audit after that change. Do not mark the documentation audit
complete merely because files exist or their headings match.

## P9. Demonstrate each sprint increment at handover

### Purpose

Every sprint ends with a developer-led, live increment demonstration to the
Product Owner before the Product Owner is asked to accept the sprint
documentation or close the sprint. The developer operates the actual product
or opens the actual delivered artifact in front of the Product Owner. A slide
deck, recording, screenshot, test log, or claim that a command ran earlier
does not substitute for this demonstration. This adds a review step to the
existing RUP wrap-up; it does not change the canonical sprint states, PBI
acceptance criteria, or Product Owner decision rights. A demonstration is
required even for a non-code-bearing iteration:
show the actual delivered document, experiment, or decision outcome rather
than pretending that an executable feature exists.

This local practice follows the [Scrum Guide's Sprint Review purpose](https://scrumguides.org/docs/scrumguide/v2020/2020-Scrum-Guide-US.pdf):
inspect the sprint outcome together and determine future adaptations in a
working session.

Demo day should leave the Product Owner confident and satisfied that the
time and money invested produced an understandable, useful result. The
Product Owner should be able to answer: what was promised, what was
delivered, how does it work, what can a user accomplish now, what remains
uncertain, and what should happen next? Earn that confidence through direct
inspection and honest discussion. Record the Product Owner's actual reaction;
the developer cannot declare the Product Owner satisfied on their behalf.

### Prepare the demonstration

The developer owns and presents the handover. Prepare one coherent user
journey tied to the sprint goal and assigned PBIs. Identify local
prerequisites, exact actions, expected visible results, and one relevant
failure or limitation to show. Run a preflight and rehearsal on the intended
environment before inviting the Product Owner. State benefits only when the
demonstration or evidence supports them; do not invent a return on investment.

### Run demo day

1. Set the context in product language: the user problem, sprint goal, and
   specific outcome promised for this sprint.
2. Start with a known product or artifact state and real input. Perform the
   user actions in order. Show intermediate results and the final output so
   the Product Owner can follow the complete path from input to useful
   outcome. For model-backed behavior, use actual model inference when
   claiming model capability; label synthetic or injected data as a contract
   check.
3. Let the Product Owner inspect the result, try a step where practical,
   ask questions, and request a repeat or alternative input. Explain what
   can now be done with the increment and what still requires work.
4. After the journey, show the relevant failure or limitation and the
   supporting test or benchmark evidence. Explain which parts were delivered
   this sprint, what the investment established, and which questions remain
   for later decisions.
5. Discuss feedback and what to change next. In managed mode, ask for the
   Product Owner's explicit handover decision through the existing process.

If the live journey cannot run, record the blocker and arrange a corrected
demonstration. Do not treat slides or earlier test evidence as a completed
live demo.

### Prepare the handover material

Update `progress/sprint_N/user_manual.md` as the sprint handover source for the
increment that a user can actually operate or review. A release-ready copy may
be promoted to `docs/` after review, with its scope and links reconciled.
State prerequisites, supported tasks, exact steps and
expected results, recovery from common errors, and known limits. If an
iteration has no executable behavior, explain how the Product Owner can
inspect its delivered artifacts and why normal product-use steps do not yet
apply. Create a concise slide presentation at
`progress/sprint_N/sprint_N_increment_demo.pptx`. Build the deck around the
same complete user journey as the live demonstration: user need and sprint
promise, starting state and input, the product actions in order, visible
intermediate and final results, and the task the user can now complete.
Give this walkthrough enough space to be understandable without the
developer's narration; a single agenda or step-list slide is insufficient.
Use real product screens, output, or delivered artifacts when they help the
Product Owner see what happened. Then state what was delivered against the
sprint goal and PBIs, material limitations or failures, supporting test or
benchmark findings, and the feedback or decision sought. Evidence supports
the product story; it must not displace the walkthrough. Slides support the
live demonstration, and detailed proofs belong in the sprint records linked
from the manual or presentation.

### Check quality and record the decision

Before the meeting, the developer checks every factual claim against the
current build, accepted scope, and sprint evidence. Execute each command
presented as copyable on the stated environment; show actual prerequisites
and expected output, and label paths or commands that require local staging.
Distinguish synthetic or reference-injected contract tests from real-model or
real-user behavior. Recheck links, slide readability, exported slide content,
and the consistency of the manual, slides, README, implementation record,
test record, benchmark where applicable, and progress board. Record the
preflight and rehearsal results, live steps performed, observed results,
Product Owner questions, and remaining demonstration limits in
`progress/sprint_N/sprint_N_handover.md`. A broken example, unsupported claim,
missing material limitation, unreadable slide, or live-demo blocker prevents
handover acceptance until corrected. A known product failure may be shown if
its effect and follow-up are made explicit.

In managed mode, inspect the outcome together with the Product Owner and
discuss what should change next. Capture questions, reactions to the user
journey, and feedback in the handover record, then request an explicit
review decision. The Product Owner may accept the handover, request
corrections, or direct new scope through the existing backlog and sprint
procedures. Do not infer acceptance from silence or from passing automated
tests. Continue the canonical Phase 5 documentation approval and sprint
status procedure only after the demonstration decision is recorded; this
patch does not itself mark a sprint complete or authorize a remote push.
