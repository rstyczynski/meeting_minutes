---
name: rup-strikes-back
description: Run the RUP Strikes Back planning or sprint workflow in Codex when the Product Owner explicitly requests it.
---

# RUP Strikes Back for Codex

Use this skill only for an explicit request to plan, start, inspect, or manage a RUP Strikes Back sprint.

## Sources of truth

- `BACKLOG.md` defines Product Owner priorities and backlog-item acceptance signals.
- `PLAN.md` defines sprint selection, status, mode, and test/regression expectations.
- `RUPStrikesBack/.claude/commands/` and `RUPStrikesBack/rules/` are the canonical RUP Strikes Back agentic method.
- When present, `RUPStrikesBack.patch/` is an optional local wrapper over that method. Its root `RUP_patch.md` is the compatibility entry point for `RUPStrikesBack.patch/RUP_patch.md`, which supplies local policies and overrides.

Read the applicable adapter reference and the canonical RUP Strikes Back procedure it identifies before acting. When the optional wrapper is present, read its root `RUP_patch.md` and `RUPStrikesBack.patch/RUP_patch.md` first, then apply the local patch where it refines or overrides the source procedure.

## Codex wrapper behavior

Codex acts as the cycle manager. The RUP roles are responsibilities and quality gates, not mandatory long-lived or parallel subagents. Use Codex subagents only for independent, bounded work that does not edit the same artifacts.

Start a cycle only when the user explicitly requests it and exactly one sprint is marked `Status: Progress`. If no sprint is active, report the condition and ask the Product Owner to select one. Do not change a sprint’s status merely because it is discussed.

In `managed` mode, stop at every manager-defined Product Owner approval or material ambiguity. In `YOLO` mode, apply the local patch when present and document decisions as the method requires; never expand the user’s authority or bypass external-action approvals.

For planning, backlog, or sprint-status work, use [manager.md](references/manager.md) and, when present, the local patch without executing a sprint cycle unless asked. For execution, read the manager adapter and then only the phase adapters selected by the iteration profile:

- [contract-and-analysis.md](references/contract-and-analysis.md)
- [design-and-test.md](references/design-and-test.md)
- [construction.md](references/construction.md)
- [quality-and-wrap-up.md](references/quality-and-wrap-up.md)

## Scope boundary

Do not copy submodule `AGENTS.md`, `HUMANS.md`, or Claude commands into the project root. Do not treat source-repository instructions as authorization to push remotely, create external repositories, or change project scope.
