# RUP Patch — Method Adoption and Iteration Semantics

## P0. Include RUP Strikes Back as a controlled project method

The project adopts RUP Strikes Back through the `RUPStrikesBack` Git submodule, tracked on the selected method branch and pinned by this repository’s Git submodule revision. The submodule is the source for the generic manager, phase-agent procedures, sprint/backlog formats, and generic rules.

The project root contains the local adoption layer:

1. `.gitmodules` registers the RUP Strikes Back submodule and selected branch.
2. `AGENTS.md` tells Codex where the method is and when to use it.
3. `RUPStrikesBack.patch/RUP_patch.md` records project-specific method refinements and overrides; the root `RUP_patch.md` is its compatibility entry point.
4. `.agents/skills/rup-strikes-back/SKILL.md` is the Codex wrapper for explicit RUP planning and sprint-execution requests.
5. `BACKLOG.md` holds Product Owner priorities and backlog-item acceptance signals.
6. `PLAN.md` holds RUP Strikes Back sprint definitions, statuses, modes, and quality expectations.

Do not copy the submodule’s `AGENTS.md`, `HUMANS.md`, `RUP_patch.md`, or Claude command files into the project root. The local `AGENTS.md`, this patch, and the Codex skill provide the project-specific integration layer while the submodule remains the single source for generic method content.

Update the submodule only through an explicit Product Owner request. Before adopting an update, review the changed method rules, confirm that this patch and the Codex wrapper still apply, and commit the resulting submodule revision together with any required local changes. Do not update the method during an active sprint unless the Product Owner explicitly treats it as a process change.

## P0.1. Initialize process artifacts when needed

`BACKLOG.md` and `PLAN.md` are created before the first sprint. Progress artifacts, including `PROGRESS_BOARD.md` and sprint-specific records under `progress/`, are created and maintained by the RUP Strikes Back cycle when a sprint starts; do not create placeholder progress files in advance.

Before the first code-bearing sprint, define the project’s test profile in this patch or a referenced project rule. It must map the generic test and regression fields to the actual macOS/iOS build, unit-test, integration-test, offline-operation, and privacy/capture validation commands. Do not claim that the submodule’s sample shell-test commands apply to this project.

## P0.2. Generic artifacts bootstrap Sprint 0

`RUPStrikesBack.patch/bootstrap/` contains reusable RUP roadmap, backlog, and sprint-plan templates. These artifacts are inputs to Sprint 0 only; they are not product requirements, active backlog items, or active sprint definitions.

Sprint 0 establishes the product vision and derives this project’s real roadmap, Product Backlog, and subsequent sprint plan from that vision. After Sprint 0, the root project artifacts—not the generic templates—are the sources of truth for the project’s scope and delivery work.

## P0.3. Place project artifacts by lifecycle role

The root `README.md` holds the accepted product vision and project orientation. `docs/` holds durable shared project deliverables created and accepted during sprints, such as requirements, architecture, decisions, and operating documentation.

`progress/sprint_N/` holds the evidence and review artifacts for one sprint. `tmp/` holds provisional material retained only for reference; it is not a source of truth and must be recreated in `docs/` or another approved location when a sprint formally delivers it. `RUPStrikesBack.patch/bootstrap/` remains the reusable bootstrap input described above.

## P1. Every sprint runs a complete agentic lifecycle

Each RUP Strikes Back sprint runs the complete agentic cycle: contracting/inception, elaboration, construction, quality validation, and wrap-up. The cycle is a feedback loop, not a waterfall handoff.

The depth of each activity is proportional to the sprint’s purpose, risk, and the project’s current RUP lifecycle phase. An activity may be brief when prior work remains valid, but it must be consciously reviewed rather than silently skipped. Any activity that is not applicable must be recorded with its reason.

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

The project root `BACKLOG.md` is the source of Product Owner priorities. The project root `PLAN.md` is the source of sprint selection and status. The root `RUP_patch.md` points to `RUPStrikesBack.patch/RUP_patch.md`, which defines local policy that supplements or overrides the generic method in the `RUPStrikesBack` submodule.

To start a sprint, the Product Owner changes that sprint’s status in the root `PLAN.md` from `Planned` to `Progress` and invokes the RUP Strikes Back cycle manager, `RUPStrikesBack/.claude/commands/rup-manager.md`, in the declared mode. In this project, the agent reads the manager and its phase-agent definitions from `RUPStrikesBack` and applies this local patch before executing the sprint.

`rup-manager` is the method entry point. Its Claude slash-command form, `/rup-manager`, is not registered as a native Codex command in this workspace; in Codex, the Product Owner explicitly asks the agent to execute the manager document for the active sprint. Managed mode remains the default: the agent pauses for Product Owner approval at the defined decision points.
