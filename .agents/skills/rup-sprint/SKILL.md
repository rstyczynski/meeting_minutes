---
name: rup-sprint
description: Create, activate, close, inspect, or change a RUP sprint in PLAN.md. Use before any PLAN.md or sprint-status change; do not use to define or promote backlog items.
---

# RUP Sprint Adapter

Use this skill for every mutation of `PLAN.md` or a sprint's lifecycle status.

## Mandatory procedure

1. Read `RUP_patch.md`, then `RUPStrikesBack.patch/RUP_patch.md`.
2. Read `RUPStrikesBack/.claude/commands/sprint.md` and
   `RUPStrikesBack/rules/generic/sprint_definition.md`.
3. Read `PLAN.md`, `BACKLOG.md`, and `PROGRESS_BOARD.md` before deciding the
   affected sprint and its assigned PBIs.
4. Validate sequential numbering, required fields, valid transitions, and that
   every assigned PBI exists in `BACKLOG.md` and is not in another active
   sprint.
5. When the procedure requires a progress-board update, create or update only
   rows whose PBI is assigned to the named Sprint in `PLAN.md`.

Do not add, promote, or reprioritize a PBI here. Route those decisions to
`rup-backlog`; stop for a Product Owner decision when the intended assignment
or transition is ambiguous.
