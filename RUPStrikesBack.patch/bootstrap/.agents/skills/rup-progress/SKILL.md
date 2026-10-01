---
name: rup-progress
description: Update or inspect RUP execution tracking in PROGRESS_BOARD.md. Use before any PROGRESS_BOARD.md change; only track a named sprint and its assigned backlog items.
---

# RUP Progress-Board Adapter

Use this skill for every mutation of `PROGRESS_BOARD.md`.

## Mandatory procedure

1. Read `RUP_patch.md`, then `RUPStrikesBack.patch/RUP_patch.md`.
2. Read the Progress Tracking section in
   `RUPStrikesBack/rules/generic/GENERAL_RULES.md` and the canonical procedure
   for the phase or sprint operation causing the update.
3. Read `PLAN.md`, the current board, and the active sprint evidence before
   changing a row.
4. Preserve the canonical four-column board. A backlog-item row must name the
   Sprint that assigns it in `PLAN.md`; never create an unscheduled or
   standalone PBI row.
5. Update only the affected sprint and assigned-PBI rows. Do not rewrite prior
   sprint history, alter `BACKLOG.md`, or change `PLAN.md` from this skill.

Stop when the source procedure does not define a valid state transition or the
PBI is not assigned to the Sprint.
