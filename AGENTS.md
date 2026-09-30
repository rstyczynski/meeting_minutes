# RUP Strikes Back Process

This project uses the `RUPStrikesBack` submodule as its agentic delivery method.

## Process entry point

The method orchestrator is `RUPStrikesBack/.claude/commands/rup-manager.md`. Its phase agents are in `RUPStrikesBack/.claude/commands/agents/`.

The root `BACKLOG.md` is the Product Owner’s prioritized backlog. The root `PLAN.md` is the sprint plan and identifies the active sprint. The root `RUP_patch.md` contains local policy that supplements or overrides the generic RUP Strikes Back method.

For an explicit request to start, plan, inspect, or manage a RUP Strikes Back sprint, read and use `.agents/skills/rup-strikes-back/SKILL.md`. Do not load that workflow for ordinary product, documentation, or implementation requests.

## Starting a sprint

Do not start a RUP cycle automatically. Start one only when the Product Owner explicitly requests it and the selected sprint has `Status: Progress` in the root `PLAN.md`.

Before executing the cycle:

1. Read `RUP_patch.md`.
2. Read `RUPStrikesBack/.claude/commands/rup-manager.md`.
3. Read the phase-agent and rule documents required by the manager.
4. Apply local patches when they conflict with or refine the generic method.

Codex does not natively register the submodule’s Claude slash command. An explicit request to execute `RUPStrikesBack/.claude/commands/rup-manager.md` for the active sprint is the Codex invocation.

## Scope

The submodule’s instructions describe the adopted delivery method. They do not authorize unrelated actions such as remote pushes, copying submodule policies wholesale, or changing project scope without a Product Owner request.
