# Sprint 2 increment handover

Status: the Product Owner directed that the minutes-content defect be recorded
as a prototype result and a direction for further work. The generated minutes
are not accepted as correct. Live walkthrough and handover decision are
pending. Sprint 2 remains `Progress` in
`PLAN.md`. This record does not claim Phase 5 documentation approval.

## Purpose and review material

The Product Owner asked for a developer-led handover under P9 of the local
RUP patch. The [user manual](user_manual.md) gives prerequisites, runnable
commands, expected results, and recovery. The current [16-slide demonstration
deck](sprint_2_increment_demo_architecture_20261004.pptx) starts with the
Sprint goal, system architecture, and the distinct ASR and minutes-model
interfaces before the real-meeting journey. It includes concise excerpts
of the staged prompts; the [implementation prompt ledger](sprint_2_implementation.md#model-prompt-ledger-and-response-gate--2026-10-02)
holds their full text. The earlier [14-slide deck](sprint_2_increment_demo.pptx)
is retained as historical presentation evidence. The [quality review slides](sprint_2_quality_review_20261004.pptx)
show the staged control architecture, measured coverage, and source-audit
failures. The [Product Owner presentation
brief](sprint_2_product_owner_presentation.md) explains the promise,
observed outcome, and review position in one place. The [implementation record](sprint_2_implementation.md#product-owner-walkthrough--real-local-models)
and [functional tests](sprint_2_tests.md) contain lower-level execution
evidence. The [benchmark](ami_asr_benchmark.md) interprets model measurements.
The [documentation audit](sprint_2_documentation_audit.md) tracks consistency.
The Product Owner must see the actual product operated live and be able to
inspect or challenge a step before an acceptance decision is requested.

The 4 October staged 30B experiment is documented in the
[controlled trial report](tests/multistage_minutes_trial_20261004.md).
It preserved every raw segment and assigned every reading utterance in
both real meeting excerpts, but only 2/5 AMI and 2/4 Sejm topic summaries
were fully supported by their own cited ASR lines. Its Sejm decision
extraction found one of two explicit signals in the saved excerpt. The
quality-review slides passed package, layout, font, and reimport checks and were
rendered for visual inspection. The earlier live-journey rehearsal below
uses the historical single-call model; a fresh operator walkthrough of
the staged candidate is still required before handover acceptance.

The journey starts with two real multi-person inputs: the [AMI ES2002a
English meeting](ami_es2002a_fixture.md), which has a weak-headset
participant, and a ten-minute excerpt from an [official Polish Sejm
committee sitting](polish_sejm_meeting_fixture.md). Their media and the
model weights are staged under `/private/tmp`, outside Git. The Polish
FLEURS sentences are retained only for a separate read-speech language
benchmark; they are not meeting-demo inputs. No reference-injected answers
are used in the real-model journey.

## Fresh presentation rehearsal — 2026-10-02

The final presentation uses a fresh store under
`/private/tmp/meeting-sprint2-po-rehearsal.wFIPLx`. The [full AMI
record](tests/43CE873A-603C-473F-9B23-A785A0689456.json) contains 2,582
timed segments, three anonymous speaker clusters, and 16 weak-audio warnings.
The first warning identifies S3 at 19.32–20.36 seconds. The developer saved
`S2 = Ada (demonstration alias)` solely to show the manual entry operation;
it is not a participant identity. The [Sejm
record](tests/5DC83D71-D1B0-4568-A66D-70F3B9A71D46.json) contains 801
timed segments, three anonymous clusters, zero warnings, and no names.
No full Sejm cluster was given the chair's name in this walkthrough.

The separate [120-second AMI minutes
record](tests/4395B92A-60B8-4B8C-9A20-3AE37642FE92.json) retains neutral
speaker names and three draft review items. One question adds a
remote-control meaning that its cited utterance does not establish; another
adds inferred setup context. The Sejm record has four draft items. The cited
positive-opinion decision is supported by the source, while the action
misclassifies a request to present and the open question is invented from a
statement. Both summaries lack citations. These are visible product failures,
not accepted minutes.

Direct calls to the debug-built CLI completed transcription and recognition,
but its two `summarize` calls aborted with an adapter `NSRangeException`.
Repeating `summarize` for the same saved records through the documented
`swift run meeting-summarizer` entry point succeeded and persisted the
drafts described above. The exact cause of the launcher difference was not
established. This rehearsal uses `swift run` throughout and does not claim
that the direct debug-binary path passed.

The paragraphs below retain earlier exploratory runs as historical
evidence. Their record IDs, segment counts, and unsafe Sejm S1 name
assignment do not describe the final presentation journey.

## Developer preflight and rehearsal

On 2026-10-02, the developer checked the staged WAVs, model directories,
adapters, Xcode and Metal shader library. Direct `swift run` commands from
the repository root executed real local inference and persisted JSON
records. The initial demonstration used a Polish FLEURS sentence. The
Product Owner rejected that as a meeting example, so it is excluded from
the revised journey. The corrected Polish source has an official recording
entry and full sitting record naming the chair and other speakers. The
revised deck and manual use the Sejm excerpt.

English AMI transcription with Parakeet v2 saved 2,576 timed segments in
record `F5014B22-206C-42EA-A35B-C4F67BE3FF02` in
`/private/tmp/meeting-sprint2-live-demo-20261002`. The full-record Fluid
speaker pass saved S1, S2, and S3 with 16 low-speech-level warnings; the
first spans about 19.3–20.4 seconds for S3. AMI annotates four participants,
so the weak participant was merged with another speaker. The manual name
operation saved `S2 = Ada (demo label)`; that is deliberately invented and
is not a claim about anyone's identity. An English 120-second meeting excerpt
saved six local-model draft minutes items in record
`D9FF6668-D722-42BE-BC1F-5B20B3A21272`. They repeat the invented name,
include unsupported content, and contain a summary item with no cited
segments. These are not publishable minutes.

The corrected Polish Sejm excerpt is a 600-second, mono, 16 kHz WAV.
Parakeet v3 saved 802 timed segments in record
`CA95C7AB-695E-4501-9176-938F0D463DFC` in
`/private/tmp/meeting-polish-gor-sprint2`. Fluid diarization saved S1,
S2, and S3, first observed at about 108, 222, and 582 seconds; it saved no
weak-audio warnings. The official written record identifies Ryszard Petru
as chair on the opening turn, which broadly aligns with S1, so the manual
name operation saved `S1 = Ryszard Petru`. The entire S1 cluster has not
been independently verified. The first local MLX minutes attempt exited
with status 2 because the model cited `S1` as a source ID. After a citation
prompt and owner-validation repair, the same command saved four draft items.
One decision is supported by its cited turn, but an invitation to present
was mislabeled as an action, and the cited source does not contain the
generated open question. The summary has no source citation. The
[Polish run capture](tests/polish_sejm_meeting_run_20261002.json) records
source IDs, hashes, observed counts, the repair, and these failures. The official
written record is edited and not time aligned, so no whole-clip Polish
meeting WER or diarization accuracy is claimed.

A stronger summary-citation prompt was tried on the same record and
discarded: it switched to English and introduced unsupported budget
details. At that rehearsal the adapter was `minutes-v2`; it has since been
replaced by the approved evidence-first response gate described below.
The rehearsal code passed six Sprint test gates, but those structural
tests did not establish minutes content quality.

The Product Owner requested a longer English public meeting as another
test source. A 30-minute excerpt from a [U.S. Department of Energy
advisory committee meeting](doe_itiac_day2_fixture.md) now provides a
real multi-person recording and official speaker-labeled transcript.
Parakeet v2 saved 4,216 timed segments; Fluid assigned eight anonymous
speaker IDs. Both the current 4B minutes model and a separately staged
7B alternative failed to parse structured output on that full record,
leaving zero review items. On the ten-minute Sejm transcript, the 7B
alternative returned structured items but still misclassified an agenda
transition and cited a range that precedes the decision. The [benchmark](ami_asr_benchmark.md#polish-meeting-minutes-quality-check)
explains the controlled comparison. No alternative has been promoted to
the product default.

A copy of the deck's multi-line shell scenario failed when SwiftPM attempted
to create an inner sandbox inside the Codex filesystem sandbox; the error
was `sandbox-exec: sandbox_apply: Operation not permitted`. This does not
invalidate the individually executed direct CLI commands, but the combined
shell replay is not counted as a pass. The deck's copyable Bash blocks passed
`bash -n`. The live Product Owner demonstration should use direct CLI calls
and show each saved JSON record. The review-player app was not opened or
played during this rehearsal; its latest bounded playback change awaits
manual replay.

## What Sprint 2 establishes and does not establish

The prototype met its architectural learning purpose in one important
respect: the staged minutes path preserved all 217/217 AMI and 801/801 Sejm
raw segments, assigned all 21/21 and 32/32 reading utterances to proposed
topics, and produced inspectable drafts. The preceding one-call 30B design
produced only one quoted AMI brief and no Sejm minutes. However, the
source-support audit passed only 2/5 AMI and 2/4 Sejm topic summaries. A
room-equipment discussion was merged with the designed remote-control
topic, and some Polish budget and PKN claims lacked sufficient cited words.
These are semantic failures, not speaker-label mistakes or JSON-format
failures. The [controlled trial](tests/multistage_minutes_trial_20261004.md)
preserves the source-linked comparison and raw attempts. The Product Owner
directed us to treat the failure as useful prototype learning, without
accepting the draft minutes or completing the sprint review.

The next evidence step is to build human-reviewed reference topics and
claim-level judgments on representative English and Polish meetings,
measure decision and task precision and recall, and compare untouched ASR
with audio-reviewed operator corrections. The operator must be able to
inspect each uncertain timed range, correct words reversibly, and verify
speaker identity from audio before applying a name to an entire cluster.
The current AMI diarizer produces three clusters for four reference people;
the low-quality participant is merged, so a single name cannot safely be
applied to that cluster. The Sejm PDF supports passage-level review but
does not supply a time-aligned whole-meeting Polish WER or speaker score.
Those limits remain visible in the [benchmark](ami_asr_benchmark.md) and
[Polish source review](tests/polish_sejm_pdf_transcription_review_20261002.md).

PBI-011 delivered a local Swift prototype with separate transcription,
speaker labeling and name assignment, optional draft minutes, a persistent
JSON record, configurable local adapters, and a review player. The English
and Polish meeting runs show the real ASR and speaker-labeling path.
The [official-PDF passage review](tests/polish_sejm_pdf_transcription_review_20261002.md)
finds the Polish meeting's main turns and decision recognizable, alongside
name, acronym, word, and numeric-unit errors needing correction. A
whole-excerpt word error rate and speaker score remain unmeasured.
The Polish structural minutes failure is repaired, but both English and
Polish minutes drafts fail content review. No production-quality minutes
are claimed.

PBI-018 measured FluidAudio/Parakeet and whisper.cpp/Whisper on the same
AMI headset input: whole-meeting WER was 19.48% and 28.79% respectively.
Five read-speech FLEURS clips per language supported a limited bilingual
model comparison, not a Polish meeting score. The benchmark records resource
use, the weak-speaker comparison, Whisper Metal load failure, and a mixed
`auto` language failure. Sprint 3 PBI-012 analyzes these results before an
architecture selection. The new Polish meeting run gives that analysis an
additional real input and an observed minutes failure.

## Product Owner feedback and pending review

The Product Owner moved the manual into the Sprint 2 process directory and
rejected the original slide deck because it did not show the product demo.
The deck was rebuilt around the need, starting state, each product action,
visible records, outcome, benchmarks, and failures. The Product Owner then
rejected FLEURS as meeting material and approved using an official Sejm
sitting. The corrected walkthrough now uses the real Polish multi-person
source. These corrections are preparation, not handover acceptance. The
Product Owner then identified the Polish minutes defect as blocking and
explicitly said the increment is not ready for delivery. The developer
repaired the structural citation and owner handling, but the model's
remaining content errors still blocked a credible minutes demonstration at
that point. The Product Owner subsequently directed us to present those
errors as measured prototype findings and a guide to further work. This
supersedes the earlier conclusion that minutes quality alone blocks the
Sprint 2 prototype handover; it does not approve the draft minutes.

The revised deck, brief, and manual are prepared for a live Product Owner
walkthrough of the actual inputs and outputs, including the known failures.
The Product Owner must be invited to
inspect a transcript, warning, speaker mapping, or minutes failure and to
request a repeat. Questions and reaction to that walkthrough, followed by
an explicit accept-or-correct decision, remain to be recorded here. The
open minutes defects prevent acceptance of dependable minutes. No
commit, Phase 5 documentation completion, sprint closure, or remote push
is inferred from rehearsal results.

## Delivery-blocker follow-up — 2026-10-02

The [DOE minutes diagnostic](tests/doe_minutes_failure_diagnosis_20261002.md)
now retains the 4B adapter's raw response from the same 30-minute
transcript. It is truncated in the middle of a JSON string after the model
ignored requested item and citation limits. The 7B failure remains less
specific because its raw response was not saved. The same diagnostic
reproduces the direct debug-binary MLX exception on the short AMI record,
while `swift run --skip-build` succeeds on that record. The documented
`swift run` route remains the supported Elaboration path.

The Product Owner approved the [minutes-quality recovery
amendment](sprint_2_design.md#approved-minutes-quality-recovery-amendment--2026-10-02).
It defines evidence-first draft items, a technical response-validation
gate with bounded repair, and an explicit ten-minute prototype limit.
The test skeleton and implementation now exercise those contracts, but
the first real-model trials still fail to produce useful, fully cited
minutes. The current presentation records that historical failure; it is
not a live handover or an acceptance of minutes quality.

## Larger local model check — 2026-10-03

The staged 30B Qwen3 candidate was run on clean copies of the same AMI
120-second and Sejm ten-minute transcript records. The [trial
report](tests/qwen3_30b_minutes_trial_20261003.md) brings the raw model
attempts, stored results, source review, runtime, and memory into one
decision-facing record. AMI passed the technical gate after citation
repair but saved only a quotation of the design brief. Sejm repeated
malformed JSON through both repair requests, so no minutes were saved;
its proposed decision also omitted a required source chunk. The model
remains an evaluated alternative, not the default. This check does not
establish usable minutes or complete
the live handover.
