# Sprint 2 — staged minutes trial on two saved meeting transcripts

Status: measured prototype experiment, **not accepted meeting minutes**.
The Product Owner approved the staged repair after the one-call approach
failed. This report uses the same saved 120-second English AMI and
approximately ten-minute Polish Sejm ASR records as the earlier
[30B one-call trial](qwen3_30b_minutes_trial_20261003.md). The model is the
local 4-bit `qwen3-30b-a3b-instruct-2507` through MLX Swift. No operator
word correction was applied to either saved ASR transcript. Structural
checks and the content judgment below answer different questions.

## What the final recorded runs produced

The final AMI run preserved **217/217** raw timed segments, formed **21**
reading utterances, assigned **21/21** to one or more of five topics, and
saved five prose topic summaries. It saved no decision, action, task, or
open question. It took **24.981 seconds** and reached **16.01 GB** maximum
child-process resident memory. The exact [metrics](multistage_20261004/ami/metrics.json),
[cleanup proposals](multistage_20261004/ami/cleanup.json),
[saved record](multistage_20261004/ami/record.json), and
[stage responses](multistage_20261004/ami/) allow inspection. A previous
same-input one-call run saved one exact source quotation after repair but
did not give a topic-level account; it took 11.97 seconds in that trial.

The final Sejm run preserved **801/801** raw timed segments, formed **32**
reading utterances, assigned **32/32** to one or more of four topics, and
saved four prose topic summaries plus one candidate budget-opinion decision.
It took **53.410 seconds** and reached **17.34 GB** maximum child-process
resident memory. The earlier one-call run saved no minutes after two
malformed-response repairs and took 26.32 seconds. The final Sejm
[metrics](multistage_20261004/sejm/metrics.json),
[cleanup proposals](multistage_20261004/sejm/cleanup.json),
[saved record](multistage_20261004/sejm/record.json), and
[stage responses](multistage_20261004/sejm/) are the direct evidence.
The time and memory numbers are single observed runs on this Mac, not
latency distributions or deployment sizing guarantees.

## Content review against the cited saved transcript

For this small manual audit, a topic summary passes only when **every
material claim** follows from its own cited utterances in the saved ASR
record. This checks source support, not whether ASR heard the audio
correctly. The denominator is the model's own proposed topics; there is
no annotated gold topic inventory, so this is not topic precision or
recall against the original recordings.

On AMI, **2 of 5** summaries pass that strict citation audit. Team
introductions (`t2`) and the product-design brief (`t3`) follow from their
cited lines. The kickoff summary (`t1`) adds goals and plans not stated
in its sole cited utterance. The logistics summary (`t4`) changes the
ASR phrase “PowerPoint reservation” into making a presentation. The
remote-control functionality summary (`t5`) cites `utt_10` and `utt_13`,
which concern plugging in and operating something in the meeting room;
the later product brief at `utt_21` concerns a remote control to be
designed. This is a topic-meaning and source-inference error. The cited
AMI utterances and topic assignments are in the [saved record](multistage_20261004/ami/record.json).
The speaker labels do not explain that semantic mix-up.

On Sejm, **2 of 4** summaries pass the same strict citation audit. The
time and room interruption (`t1`) and positive budget opinion followed
by transition (`t3`) are supported by their cited lines. The budget
figures summary (`t2`) cites `utt_7` and `utt_8`; `utt_8` ends at
“35 867”, while the unit appears in the following utterance. The PKN
summary (`t4`) cites only `utt_32`, which states organization and
supervision of standardization work; the summary additionally claims
statutory tasks and financing without citing the words needed to support
them. An earlier staged Sejm candidate also named the wrong committee
as the author of the positive opinion. That candidate remains in
[preserved evidence](multistage_20261004/sejm_before_topic_fix/record.json);
the final run avoided that particular wording but has the citation
failures just described.

The Sejm candidate decision is supported by `utt_29` and is attached to
the opinion-and-transition topic `t3`. A targeted review of the **two
explicit decision signals in this saved excerpt** found the positive
budget opinion at `utt_29` and the previous protocol's acceptance at
`utt_5`. The candidate extracted the former and missed the latter:
**1/2 found within this deliberately narrow ASR reference set**. Its
one saved decision has supporting words in the cited utterance. This
does not measure overall decision recall or audio-level truth.

## Transcript cleanup and operator boundary

The final Sejm cleanup identified **16** candidate segment joins: 12
single-token bridges between the same labeled speaker and four
`joinPrevious` proposals. Those four join the formerly unassigned
“przedstawienie tej tego budżetu” continuation after the chair's request
into the same reading utterance, while retaining all original segment
IDs and labels in the raw transcript. The earlier candidate left part
of that phrase in a separate unknown-speaker utterance; its evidence is
preserved at [the pre-continuation run](multistage_20261004/sejm_before_continuation_fix/record.json).
The deterministic proposals are **not** audio-confirmed speaker
identification. The operator can replay the range and use
`transcribe correct` to save an audio-reviewed, reversible text
correction. Neither final model run used such a correction, so no
manual improvement is included in the measured quality.

## Technical response behavior and decision

The model previously returned malformed JSON, too many narrow topics,
unsupported decision/task candidates, and quotes that crossed or differed
from cited utterances. The staged adapter validates each response,
requests at most two repairs, and saves no new minutes if a stage still
fails. Its narrow last-attempt quote shortening retains only an exact
contiguous fragment from the already cited utterance. One AMI rerun
still failed before that adjustment; the [failed attempt](multistage_20261004/ami_failed_short_quote/run.log)
is kept. The successful runs establish that structural recovery is
possible, not that inference is deterministic or that a valid citation
proves a paraphrase true.

The prototype establishes a useful architecture direction: preserve raw
ASR, offer operator audio review and reversible corrections, assign every
reading utterance to a topic, summarize each topic, and validate IDs,
source quotations, item types, and atomic storage. It does **not** meet
the quality bar for dependable natural-meeting minutes. The next
evaluation needs human reference topics and claim-level source judgments,
decision/task recall, audio-reviewed correction trials, and a longer
meeting run. The current candidate remains a review draft and a Sprint 2
architecture experiment.
