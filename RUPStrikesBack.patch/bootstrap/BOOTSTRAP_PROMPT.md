# RUP Strikes Back Bootstrap Prompt

Use this prompt to set up RUP Strikes Back for a new or existing project. It creates a generic process portfolio only; it does not infer, plan, or build a product.

```text
Work on this directory as the project’s main goal. Establish RUP Strikes Back as a controlled local development method.

First, inspect the supplied RUP Strikes Back version and its bootstrap assets. Use its formats, rules, and procedures as the method source; do not invent replacements.

If RUPStrikesBack is not already present, add https://github.com/rstyczynski/RUPStrikesBack.git as the RUPStrikesBack Git submodule at the selected version or branch. If it is already present, inspect its pinned revision. Do not update the submodule remotely or change its revision unless the Product Owner explicitly requests a method update.

Install the project-local adoption layer from the supplied bootstrap assets:

- Register the submodule in .gitmodules.
- Create the project-local AGENTS.md that directs agents to the submodule and local policy.
- Create RUPStrikesBack.patch/RUP_patch.md as the full local method patch and a short root RUP_patch.md that points to it.
- Create the local agent or skill wrapper needed by the host environment to invoke the RUP Strikes Back manager.
- Copy the generic bootstrap README.md, BACKLOG.md, PLAN.md, and ROADMAP.md into the project root when they do not already exist.

Do not copy RUPStrikesBack’s AGENTS.md, HUMANS.md, RUP_patch.md, or Claude command files into the project root. The submodule remains the generic method source; the local adoption layer records only project-specific integration and refinements.

If this directory is not a Git repository, initialize it. Do not create a remote repository, push, or create a branch unless the Product Owner explicitly requests it.

The copied root artifacts are a generic bootstrap portfolio, not a product definition or active delivery commitment. Do not invent a product vision, product backlog items, requirements, architecture, progress board, or other project artifacts. Do not start a sprint or run the RUP manager yet.

Stop after bootstrap setup and report the files created or preserved. Wait for the Product Owner to provide product intent and explicitly start Sprint 0. Sprint 0, Sprint 1, and Sprint 2 will progressively tailor the generic roadmap, plan, and backlog to the actual project; generic work is a proposed default, not mandatory ceremony.
```
