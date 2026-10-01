---
name: rup-backlog
description: Manage, promote, prioritize, or review Product Backlog items in BACKLOG.md. Use before any BACKLOG.md change; do not use to schedule a sprint or update execution progress.
---

# RUP Backlog Adapter

Use this skill for every mutation of `BACKLOG.md`, including promotion of a
proposal, adding a PBI, reprioritizing items, and changing a PBI's status.

## Mandatory procedure

1. Read `RUP_patch.md`, then `RUPStrikesBack.patch/RUP_patch.md`.
2. Read `RUPStrikesBack/.claude/commands/backlog.md` and
   `RUPStrikesBack/rules/generic/backlog_item_definition.md`.
3. Read the current `BACKLOG.md` and the proposal or evidence being promoted.
4. Apply the canonical item format and the local patch. Use the next sequential
   project PBI identifier and preserve Product Owner ordering.
5. Validate the title, two-to-four-sentence what/why description, one-line
   test criterion, and absence of design, implementation, tables, lists, code,
   or file paths unless the local patch explicitly refines the rule.

## Promotion boundary

An accepted feedback proposal may become a root PBI with `Status: Proposed`.
Do not add an unscheduled PBI to `PLAN.md` or `PROGRESS_BOARD.md`; those belong
to `rup-sprint` and `rup-progress` after the Product Owner assigns the PBI to
a named Sprint.

Stop for a Product Owner decision if promotion would alter an existing PBI's
priority, scope, or sprint assignment.
