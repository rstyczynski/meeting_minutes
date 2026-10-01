# RUP Strikes Back Local Patch

This directory is the project-local adoption layer for the `RUPStrikesBack`
Git submodule. The submodule remains the source for the generic delivery
method; this package supplies the local policy and bootstrap materials.

## Bootstrap the method

From the project root, ask Codex to read and execute
`RUPStrikesBack.patch/BOOTSTRAP_PROMPT.md`.

```md
bootstrap

@RUPStrikesBack.patch/BOOTSTRAP_PROMPT.md

Read and execute this bootstrap prompt.
```

The bootstrap flow:

1. Confirms that the project is a Git repository and preserves an existing
   `origin` remote.
2. Adds (or inspects) the `RUPStrikesBack` submodule on
   `feature/version-2.0-sprint-backlog-management`, without updating its
   pinned revision.
3. Overlays the contents of `RUPStrikesBack.patch/bootstrap/` onto the
   project root, including `.agents/`, while retaining this local patch
   directory and its operator prompt.
4. Stops if a non-bootstrap project artifact would be overwritten, so the
   Product Owner can decide how to handle the conflict.
5. Commits only the method and generic bootstrap artifacts, then pushes the
   current branch to `origin` without force.

Bootstrap establishes a generic portfolio only. It does not define a product
or execute a sprint. It preselects Sprint 0 with `Status: Progress`, ready for
an explicit Product Owner request.

## Start Sprint 0

Sprint 0 is already marked `Status: Progress` by the bootstrap plan. Ask
Codex explicitly to start Sprint 0 with the `rup-strikes-back` skill,
and supply the initial product intent. Include the intended users, their
problem, desired outcome, and important constraints.

Example:

```text
Start Sprint 0 in managed mode using the rup-strikes-back skill.
Product intent: [Describe the product, intended users, problem to solve,
desired outcome, and important constraints.]
```

Sprint 0 runs in managed mode by default. Codex will seek Product Owner
approval for the product vision (`README.md`) and then for the initial roadmap
and next-sprint proposal. The generic Sprint 0 backlog contains PBI-001
(product vision) and PBI-002 (initial project plan); the Product Owner may
refine that work based on the supplied intent.

## User preferences

The Product Owner can make a durable writing or presentation preference part
of this project's method. Preferences live in the separate, ordinary Markdown
file [`USER_PREFERENCES.md`](USER_PREFERENCES.md). Open that file to see or
edit them. Ask Codex to record a new preference there in your own words and,
if useful, say which artifacts it applies to. Codex should show the file
change for review and apply it to new or revised project artifacts. A later
explicit preference can amend an earlier one.

For example, you can say: “Add to `RUPStrikesBack.patch/USER_PREFERENCES.md`:
use paragraphs with clear headings in Markdown documents; avoid Markdown
tables in narrative reports.” The local [RUP patch](RUP_patch.md#p7-read-the-separate-product-owner-preferences-file)
requires agents to read this file during sprint work. The canonical
four-column progress board remains a table unless you explicitly request a
separate change to that method format.
