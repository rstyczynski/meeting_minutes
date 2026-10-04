# Sprint 2 presentation set for the Product Owner

**Review state:** updated with measured staged-minutes findings on 4 October 2026. Sprint 2 remains
in Progress. The Product Owner directed that the minutes quality failure be
presented as a prototype conclusion and next-work direction; the draft
minutes are not accepted as correct. The live demonstration, documentation
approval, and sprint close have not occurred.

## What this sprint promised

Sprint 2 set out to build an executable local model of the meeting workflow
(PBI-011) and compare critical technical options on common test data
(PBI-018). A chair should be able to import a real recording, obtain a timed
transcript, inspect speaker labels and weak-audio cues, assign a verified
name, and request draft minutes. The benchmark should show measured quality
and failures clearly enough to guide the Sprint 3 architecture assessment.

## Presentation and live journey

Open the current [20-slide live-journey presentation](sprint_2_increment_demo_pipeline_20261004_v2.pptx)
and follow the [single-command demo and slide-by-slide presenter script](demo/README.md).
The [operator manual](user_manual.md) documents individual commands and
recovery. Slides 2–4 establish the Sprint goal,
the shared Swift architecture, and the two model interfaces. ASR receives
audio and a language setting, not a text prompt. The staged Qwen model
receives transcript utterances and task-specific prompts; its responses go
through Swift source checks and bounded repair. The full prompt templates
are in the [implementation ledger](sprint_2_implementation.md#model-prompt-ledger-and-response-gate--2026-10-02).
Slides 5–10 then show the real meeting inputs, saved transcript and warning,
candidate cleanup, operator review, and neutral speaker labels. Slides
11–12 show source review and response gating. The demo script supplies
exact runnable commands, local model and media preflight, readable `jq`
checks, and recovery steps. The [handover record](sprint_2_handover.md)
records the developer's rehearsal and the still-pending Product Owner
walkthrough. The developer must operate the product live for handover;
the slides and this document support that inspection.

The English input is the [AMI ES2002a meeting](ami_es2002a_fixture.md) with
a documented weak-headset participant. The Polish input is a ten-minute
excerpt of an [official Sejm committee sitting](polish_sejm_meeting_fixture.md),
with a published PDF record. Both are actual multi-person meetings. Their
local audio and the model weights are staged outside Git on the Sprint 2
Mac; the deck starts from a fresh local record store. The single-speaker
FLEURS clips appear only in the separate language benchmark.

In the 4 October single-command rehearsal, `transcribe` saved 2,576
English and 802 Polish timed segments. The older handover rehearsal had
2,582 and 801; the live run prints its own observed counts. The
[Sejm PDF comparison](tests/polish_sejm_pdf_transcription_review_20261002.md)
finds the main turns, several budget amounts, and the positive-opinion
decision recognizable in the Polish transcript. It also finds errors in
names, acronyms, words, and numerical units. The PDF is edited and not
time aligned, so no whole-excerpt Polish meeting word error rate is claimed.

Next, `recognize` adds anonymous speaker labels. The AMI rehearsal saved
three clusters and 16 weak-audio warnings although the reference meeting
has four participants: the poor-headset participant was merged with
another person. The operator can review source audio and save a reversible
word correction. A name is entered only after listening to the whole
cluster. The current handover does not assign a participant name; the
historical invented AMI alias was test-only and is excluded from the live
journey. The official Sejm PDF identifies the chair on specific turns but
does not verify every segment in S1.

Slide 10 makes the CLI naming operation explicit. At stage 4 the operator
enters the verified name; the script prints the complete `recognize name`
command using the live meeting ID and store, runs it and displays the saved
map. The name applies to all utterances in the chosen cluster. Close and
reopen Meeting Review with the printed command to see the saved name.
The slide also includes a complete Terminal block for the actual currently
open Sejm record, with its UUID and store, and an input prompt for the name.
It can be pasted independently of the demo's shell variables.
The [focused CLI check](tests/speaker_naming_demo_20261004.md) confirms
persistence on a disposable copy without changing the active demo record.
It does not establish a real participant identity.

Finally, `summarize` runs the local 30B staged model and validates its
response before saving any review items. The fresh 4 October script run
rejected both model responses and retained the transcripts; its result
will be shown rather than silently replaced. An earlier controlled 30B
run saved five AMI and four Sejm topic summaries, but strict source
review supported only 2/5 and 2/4. The earlier evidence-first gate checked JSON
structure, source IDs, exact quotations, and evidence types, with at most
two specific repair requests. Controlled tests passed, but the 4B model's
real AMI and Sejm candidates failed that strict gate; the transcript
survived and no new minutes were saved. Those drafts remain source-review
evidence: AMI contained an unsupported interpretation; Sejm contained a
supported positive-opinion decision alongside a false action, invented
question, and uncited summary. These are **not dependable meeting minutes**.
The [bug record](sprint_2_bugs.md) distinguishes the repaired
citation-format error from these open content defects. The later staged
30B result is assessed below.

## What the benchmark establishes

On the same referenced AMI headset recording, FluidAudio/Parakeet v2 had
19.48% word error rate and whisper.cpp/Whisper base.en had 28.79%. For the
documented poor-headset speaker, reference-linked errors were 27.78% and
58.55%, respectively. This comparison covers one meeting and the selected
model sizes. The [benchmark report](ami_asr_benchmark.md) also records
runtime, footprint, offline execution, diarization limits, and a small
English/Polish read-speech comparison. It gives the interpretation and
limits; the [test record](sprint_2_tests.md) links raw runs and gate logs.

A longer [U.S. Department of Energy advisory committee
meeting](doe_itiac_day2_fixture.md) supplies a second real English input.
Its 30-minute excerpt yielded 4,216 timed segments and eight anonymous
speaker IDs. Both tested local minutes models failed to save review items
from that transcript. This failure does not invalidate the transcription
run, but it prevents a claim that the prototype can produce minutes for a
long meeting.

## Product Owner review position

### 4 October prototype learning: minutes quality architecture

The earlier single-call 30B experiment yielded one cited AMI quotation and
no Polish Sejm minutes. The accepted repair now processes an immutable
transcript through reversible operator corrections, topic discovery,
utterance assignment, per-topic summaries, item extraction, and source
validation. Its final AMI run conserved **217 of 217** raw segments,
assigned **21 of 21** reading utterances, and produced **five** prose topic
summaries. A strict manual audit found that only **2/5** summaries were
fully supported by their own citations. The run took **24.981 seconds**
and reached **16.01 GB** maximum child-process resident memory. Earlier
staged candidates proposed four unsupported decision/action items, which
the type gate withheld. Structure improved; content acceptance did not.

On the saved Polish Sejm transcript, the final staged run retained **801 of
801** raw segments, assigned **32 of 32** reading utterances to four topics,
and saved four prose summaries and one candidate budget-opinion decision.
The earlier same-input one-call 30B run saved no minutes. The staged run
took **53.410 seconds** and reached **17.34 GB** maximum child-process
resident memory. Only **2/4** summaries were fully supported by their own
citations; a budget unit and additional PKN claims lack adequate cited
words. The candidate detected one of two explicit decision signals found
in a targeted audit of the saved ASR excerpt. The [trial report](tests/multistage_minutes_trial_20261004.md),
[Sejm record](tests/multistage_20261004/sejm/record.json), and
[run metrics](tests/multistage_20261004/sejm/metrics.json) make these
findings inspectable.

The source review found a concrete remaining error: the model treated
remarks about setting up equipment in the room as a topic about the
remote control being designed later in the meeting. The raw speaker
labels did not cause that mix-up; it is an error in topic meaning.
Another summary turns “PowerPoint reservation” into preparing a
presentation. The model also called agenda/logistics statements and
budget figures decisions or tasks. Schema, IDs, and citations can be
checked by software, but a human must still assess whether the summary
actually follows from those words. The [new architecture diagram](../../docs/architecture_overview.drawio)
has a separate page, “Minutes quality controls,” and the
[implementation conclusion](sprint_2_implementation.md#prototype-conclusion-what-the-minutes-experiment-teaches-us)
records the reasoning and source links.

Operator audio review fills another missing product step. The review
player exposes every timed segment and source audio; the new
`transcribe correct` command saves a reversible, audio-reviewed text
correction while preserving the original ASR record. The candidate
minutes use this corrected reading, and any previous draft is cleared
when its source changes. The AMI/Sejm model comparison uses unchanged
saved ASR transcripts, so these controls have not inflated its result.

The next architecture assessment should test topic boundaries and claim
support against human reference annotations, measure the precision and
recall of extracted decisions and tasks, and determine where operator
audio review gives the largest quality gain. The Sejm multi-stage result
needs repair and a reviewed reference set before any accuracy score or
acceptance claim. No natural-meeting acceptance claim follows from the
passing technical gates alone.

The prototype and benchmark provide inspectable architecture evidence.
The minutes capability remains unvalidated because of factual and topic errors in
natural-meeting drafts and structured-output failure on the longer DOE input. The
separate [30B same-input trial](tests/qwen3_30b_minutes_trial_20261003.md)
did not establish reliable minutes: on AMI it saved only an exact citation of the
meeting brief after repair, while on Sejm it repeated malformed JSON and
left the transcript intact with no draft items. The report includes the
source-level assessment, raw attempts, elapsed time, and memory. The
review player also has a bounded-playback change that builds but still
needs a manual replay check. The current handover must therefore not be
presented as acceptance of dependable minutes or a completed Sprint 2.

The next live review should show the actual saved transcript, a weak-audio
warning, a speaker-name assignment, the operator's source-audio review
path, and the current staged AMI and Sejm drafts alongside the cited
utterances. Show the unsupported claims and the missed protocol decision,
then compare with the earlier one-call failure. The Product Owner can
inspect a record or request a repeat. Record their reaction and explicit decision in the
[handover record](sprint_2_handover.md). The measured staged candidate
still fails content quality and requires a corrected, human-reviewed
validation set before any minutes-quality acceptance.

## Reading pipeline and rule clarification — 4 October 2026

Start with goals, then use slide 3 of the [current deck](sprint_2_increment_demo_pipeline_20261004_v2.pptx) to follow audio through ASR, optional diarization, Swift reading turns, operator review, optional Qwen minutes and output validation. On slide 4, state clearly that the separate FluidAudio diarizer, not Parakeet/Whisper or Qwen, detects anonymous voice turns. Swift aligns them to timed text by overlap and groups the resulting parts.

During the operator stage show slides 19–20 with every profile field and its default. Demonstrate the [documented CLI profile](transcript_segmentation.md). Explain why a labeled speaker change ends a turn while a same-speaker pause does not, and show the number `35 779` staying together. Report 32-to-four reading blocks with 802/802 parts conserved as grouping evidence only. Use the preserved raw sources to inspect proposed unassigned joins. Meaning-based boundaries and rechecking the actual voice remain open. Reapplying a profile must not silently retain stale minutes when it changes.
