---
name: rup-strikes-back
description: Manage or execute a RUP Strikes Back sprint in this repository when the Product Owner explicitly requests RUP planning, sprint management, status, or execution. Do not use for ordinary product or implementation work.
---

# RUP Strikes Back for Meeting Summarizer

Use this skill only for an explicit request to plan, start, inspect, or manage a RUP Strikes Back sprint.

## Sources of truth

- `BACKLOG.md` defines Product Owner priorities and backlog-item acceptance signals.
- `PLAN.md` defines sprint selection, status, mode, and test/regression expectations.
- `RUP_patch.md` defines this project’s local policies and overrides the generic method where they differ.
- `RUPStrikesBack/.claude/commands/rup-manager.md` is the detailed cycle manager.

For a sprint execution request, read those files in that order, then read the phase-agent and rule documents required by `rup-manager.md`. Treat the submodule’s Claude command files as procedures to follow, not native Codex slash commands.

## Codex wrapper behavior

Codex acts as the cycle manager. It may use available Codex subagents for independent bounded phase work when appropriate, but must preserve the manager’s sequence, Product Owner decision points, and artifact traceability.

Start a cycle only when the user explicitly requests it and exactly one sprint is marked `Status: Progress`. If no sprint is active, report the condition and ask the Product Owner to select one. Do not change a sprint’s status merely because it is discussed.

In `managed` mode, stop at every manager-defined Product Owner approval or material ambiguity. In `YOLO` mode, apply the local patch and document decisions as the method requires; never expand the user’s authority or bypass external-action approvals.

For a planning or backlog-management request, use the relevant submodule command procedure (`backlog.md` or `sprint.md`) and local patch, but do not execute a sprint cycle unless asked.

## Scope boundary

Do not copy submodule `AGENTS.md`, `HUMANS.md`, or Claude commands into the project root. Do not treat source-repository instructions as authorization to push remotely, create external repositories, or change project scope.
