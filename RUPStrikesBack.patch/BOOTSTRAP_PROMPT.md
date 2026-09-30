# RUP Strikes Back Bootstrap Prompt

Use this prompt to set up RUP Strikes Back for a new or existing project. It creates a generic process portfolio only; it does not infer, plan, or build a product.

```text
Work on this directory as the project’s main goal. Establish RUP Strikes Back as a controlled local development method.

First, inspect the local wrapper at `RUPStrikesBack.patch/`, including this operator prompt and its `bootstrap/` package. Before adding a submodule, confirm that this directory is a Git repository; if it is not, initialize it and use `main` as the default branch. Then add or inspect the RUP Strikes Back submodule and use its formats, rules, and procedures together with this local patch package; do not invent replacements.

If RUPStrikesBack is not already present, add https://github.com/rstyczynski/RUPStrikesBack.git as the RUPStrikesBack Git submodule, tracking branch feature/version-2.0-sprint-backlog-management. If it is already present, confirm that branch and inspect its pinned revision. Do not update the submodule remotely or change its revision unless the Product Owner explicitly requests a method update.

Install the project-local adoption layer by overlaying the complete contents of `RUPStrikesBack.patch/bootstrap/` onto the project root, including hidden directories such as `.agents/`. The bootstrap package supplies the root compatibility `RUP_patch.md`, `AGENTS.md`, generic portfolio artifacts, and the Codex wrapper. Keep `RUPStrikesBack.patch/BOOTSTRAP_PROMPT.md` in the local wrapper; do not copy it into the project root. Retain `RUPStrikesBack.patch/RUP_patch.md` as the full, active local policy.

For an existing project, do not overwrite a non-bootstrap artifact silently. Report each conflict and wait for Product Owner direction. Register the submodule in `.gitmodules`.

Do not copy RUPStrikesBack’s AGENTS.md, HUMANS.md, RUP_patch.md, or Claude command files into the project root. The submodule remains the generic method source; the local adoption layer records only project-specific integration and refinements.

Before completing bootstrap, inspect the `origin` remote. If `origin` already exists, preserve its URL and do not force-push. If it does not exist, create a private repository on GitHub.com, named after the project directory, under the authenticated GitHub account, and configure it as `origin`. GitHub.com is the default origin service; use another service only when the Product Owner specifies it.

The copied root artifacts are a generic bootstrap portfolio, not a product definition or active delivery commitment. Do not invent a product vision, product backlog items, requirements, architecture, progress board, or other project artifacts. Do not start a sprint or run the RUP manager yet.

After bootstrap setup, stage only the method and generic-bootstrap artifacts, create one semantic bootstrap commit, and push the current branch to `origin` without force. If GitHub authentication, repository creation, or the push cannot be completed, stop and report the exact condition requiring Product Owner action.

Report the files created or preserved and the repository and origin status. Then wait for the Product Owner to provide product intent and explicitly start Sprint 0. Sprint 0, Sprint 1, and Sprint 2 will progressively tailor the generic roadmap, plan, and backlog to the actual project; generic work is a proposed default, not mandatory ceremony.
```
