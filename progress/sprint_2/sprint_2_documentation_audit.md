# Sprint 2 — Documentation reconciliation gate

Status: PBI-011.1 completion audit passed. Current documents distinguish
accepted, proposed, implemented, tested, and pending behavior. The requested
three-command CLI revision still needs the Product Owner's managed-mode design
approval and test-architecture update before its construction. That is a
separate, unresolved design gate and does not block the core/store child.
This is a pre-commit audit under P8 of the local RUP patch, not the final
Phase 5 documentation review.

The Product Owner clarified the commit boundary: complete and verify each
increment, including each tracked child PBI, then commit that increment's
code, tests, documentation, and audit together. Do not commit after every
edit. PBI-011.1 has now passed its acceptance and formal gate checks; its
completion commit is due after this audit passes. Other child PBIs and
PBI-018 remain under construction.

## Decisions and source of truth checked

The Product Owner requested independent `transcribe`, optional `recognize`,
and optional `summarize` commands, with neutral labels allowed in a summary
when recognition is skipped. Chair-controlled naming is in MVP scope;
automatic person-name suggestions remain a nice-to-have. The Product Owner
also approved critical Sprint 2 validation of low-quality audio, including
identification of an affected speaker or source ranges, original preservation,
and review of an alternate input. The root `PLAN.md` still assigns PBI-011
and PBI-018 to active managed Sprint 2. `PROGRESS_BOARD.md` accurately keeps
both under construction. The board now marks only PBI-011.1 as tested on
its implementation and gate evidence, while the sprint remains under
construction.

## Artifact reconciliation

The [SRS](../../docs/srs.md) now states the three optional CLI capabilities,
two low-quality-audio use cases, FR-09 for affected participant or range
warnings, and FR-10 for preservation and review. The
[architecture](../../docs/architecture.md) identifies its single-import
description as the accepted Sprint 1 baseline and records the proposed split
and quality-warning boundary without silently changing that baseline. The
[test profile](../../docs/test-profile.md) now names the actual `tests/run.sh`
gate commands and the Swift Testing choice, and explains the current smoke
test's `import` expectation.

The [Sprint setup](sprint_2_setup.md) records the cross-sprint SRS impact and
possible targeted review of Sprint 1 evidence. The [accepted design](sprint_2_design.md)
separates its original `import` baseline and approved FR-09/FR-10 experiment
from the proposed three-command amendment. The
[change proposal](sprint_2_proposedchanges.md) supplies concrete syntax and
test cases for that amendment. No CLI amendment is labeled accepted.

The [implementation record](sprint_2_implementation.md) gives a working
synthetic `import` example and labels all three requested commands as
non-working. The [test record](sprint_2_tests.md) records all six passing
gates for PBI-011.1 and pending tests for the proposed commands. The
[benchmark report](ami_asr_benchmark.md) now gives a self-contained comparison
of the two ASR combinations, its traceable measurements, and explicit FR-09
and FR-10 validation failures or gaps. The [AMI fixture evidence](ami_es2002a_fixture.md)
records sources, hashes, license, official participant-to-speaker mapping,
and a signal-level probe without claiming model validation. The
[README](../../README.md) now states Sprint 2 is active, links the evidence,
and distinguishes the working CLI from the proposed workflow.

## Commands and claims checked

`tests/run.sh --smoke` passed and ended with `smoke: all available test
scripts passed`. `swift run meeting-summarizer --help` advertised the current
`import` command. A direct concurrent SwiftPM invocation failed with a macOS
`sandbox_apply` error; the same help command passed when rerun outside that
sandbox. The documented synthetic `import` command produced record
`C19D02E1-F917-4AD5-BD32-6000BEAF79F3`. Inspection with `jq` confirmed
backend `fluid`, revision `synthetic-reference-v1`, five segments, and three
review items. These checks support only the current fixture-path claims.
All local Markdown links in README, `docs/`, and Sprint 2 narrative files
resolved; those files have no Markdown tables. The progress board retains
its required four-column table. `git diff --check` passed at that earlier
check. Subsequent real-model and gate results supersede the earlier pending
statements and are audited below.

After that initial check, whisper.cpp and FluidAudio completed local ASR runs
on the synthetic fixture and approved AMI meeting. The benchmark report
records matched-input quality and repeat resource measurements. Those are
still incomplete PBI-018 evidence, not a finished architecture decision.

## Mandatory action before revised CLI construction

The Product Owner must accept or revise the proposed three-command design.
After acceptance, the Test Architect must add the specified runnable
SM-2/UT-7–9/IT-7–9 skeletons and manifest entries before CLI construction.
The constructor must implement those commands, run the documented examples
and error cases, and update the implementation and test records with actual
results. This audit must then be repeated against code, SRS, architecture,
design, tests, README, test profile, and progress status before advancing.
Until then, the proposed commands remain clearly pending in every affected
document; none is counted as implemented or tested.

## PBI-011.1 pre-commit reconciliation — 2026-10-01

The root [SRS](../../docs/srs.md) and [architecture](../../docs/architecture.md)
still require a portable core and traceable local record. The
[test profile](../../docs/test-profile.md) names the actual Swift build and
six gate commands. [Sprint setup](sprint_2_setup.md) and the
[accepted design](sprint_2_design.md) assign the core/store child and its
fresh-process persistence check. The proposed CLI amendment remains pending
and is not part of this child. The [implementation record](sprint_2_implementation.md)
identifies the actual `MeetingCore` types and store, while the
[functional test record](sprint_2_tests.md) names the passing gate logs and
the strengthened IT-1 cross-process check. The [README](../../README.md)
describes only the working combined `import` command. The
[progress board](../../PROGRESS_BOARD.md) marks PBI-011.1 `tested`, while the
parent, other children, PBI-018, and Sprint 2 remain under construction.

The package built with `swift build`. Core unit tests passed in A2 and B2.
IT-1 invoked the CLI in a separate process, then loaded the persisted record
through `MeetingStore` in the test process, confirming five segments and the
source path. A1, A2, A3, B1, B2, and B3 all passed. The first A1 attempt
failed at SwiftPM's nested sandbox before product assertions; its outside-
sandbox retry passed. A3 and B3 were rerun successfully after IT-1 changed.
Exact log names and the retry are in the functional test record. The core
source files contain no `SwiftUI` or `AppKit` imports. The current synthetic
`import` example and its `jq` output were executed in the prior consistency
pass; proposed commands remain labeled pending.

All local Markdown links in README, `docs/`, and Sprint 2 narrative records
resolved in a fresh check of 13 files. No narrative Markdown tables were
found; the board retains the required four-column table. `git diff --check`
passed. The [benchmark report](ami_asr_benchmark.md) gives the Product Owner
comparative findings and evidence traceability, while explicitly leaving
speaker attribution, warnings, timing, offline operation, and minutes open.
These gaps block PBI-018 and the parent PBI-011, not the completed core/store
child. Its implementation, tests, process evidence, and current sprint
documentation are ready for a local completion commit. No remote push is
authorized.

The first code-bearing commit also captures the common Swift package,
test runners, and currently documented prototype adapters and experiments
that were developed alongside the core. Their distinct outcomes are
attributed in the design and implementation records to PBI-011.2 through
PBI-011.5 and PBI-018; this commit does not mark them complete. Each will
receive its own reconciliation, quality check, board update, and completion
commit when its acceptance evidence is ready.
