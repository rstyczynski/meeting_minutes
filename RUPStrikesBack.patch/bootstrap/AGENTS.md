# RUP Strikes Back Process

This project uses the `RUPStrikesBack` submodule as its agentic delivery method.

## Process entry point

The Codex method entry point is `.agents/skills/rup-strikes-back/SKILL.md`. Its references map Codex invocation to the canonical manager, agent-role, and rule procedures in `RUPStrikesBack/.claude/commands/` and `RUPStrikesBack/rules/`.

The root `BACKLOG.md` is the Product Owner’s prioritized backlog. The root `PLAN.md` is the sprint plan and identifies the active sprint. When present, `RUPStrikesBack.patch/` is an optional local wrapper; its root `RUP_patch.md` is the compatibility entry point for the full local policy at `RUPStrikesBack.patch/RUP_patch.md`.

For an explicit request to start, plan, inspect, or manage a RUP Strikes Back sprint in Codex, read and use `.agents/skills/rup-strikes-back/SKILL.md`. Do not load that workflow for ordinary product, documentation, or implementation requests.

## Starting a sprint

Do not start a RUP cycle automatically. Start one only when the Product Owner explicitly requests it and the selected sprint has `Status: Progress` in the root `PLAN.md`.

Before executing the cycle:

1. When the optional wrapper is present, read `RUP_patch.md`, then `RUPStrikesBack.patch/RUP_patch.md`.
2. Read the Codex skill's manager adapter and only the phase adapters selected by the iteration profile.
3. Read the canonical submodule procedures identified by those adapters.
4. Apply the local wrapper only where it conflicts with or refines the generic method.

Codex does not natively register the submodule's Claude slash commands. An explicit request to use the `rup-strikes-back` skill for the active sprint is the Codex invocation.

## Scope

The submodule’s instructions describe the adopted delivery method. They do not authorize unrelated actions such as remote pushes, copying submodule policies wholesale, or changing project scope without a Product Owner request.
