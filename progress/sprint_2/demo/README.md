# Sprint 2 — Product Owner live demonstration script

## Latest operator feedback: long silence and audio position

The Product Owner exposed a 33.28-second pause inside one S1 card. The directed repair adds `longSilenceBoundarySeconds` (10 s by default, configurable) and a full-recording slider in Meeting Review and its correction sheet. The same S1 label now appears on separate segments before/after the pause. All six gates passed at `20261004_230950`; saved-session inspection yields five segments and preserves 802/802 source parts and both text-correction events. The successful crossing edit was separately observed in the owner's saved session. Slider seeking/listening, Restore/Cancel/restart and full handover acceptance remain live checks. No ASR/LLM quality improvement is claimed.

The [manual](../user_manual.md#long-silence-and-audio-slider), [parameter guide](../transcript_segmentation.md) and [repair evidence](../tests/long_silence_review_20261004.json) describe the same current behavior.


This is the exact running order for the Sprint 2 review. Present the
[21-slide deck](../sprint_2_increment_demo.pptx) while
running the product in Terminal. The deck gives context and recorded
benchmark results; the Terminal shows a fresh execution. Say explicitly
when a result comes from an earlier controlled run. The real AMI English and
Sejm Polish recordings are multi-person meetings. The script never passes
test references to the product.

## Before inviting the Product Owner

On the Sprint 2 Mac, from the repository root, run:

```bash
bash progress/sprint_2/demo/run.sh --check
```

This checks the exact WAV recordings, Parakeet v2/v3, diarization model,
Qwen 30B weights, MLX adapter and Metal shader library. Run a CLI-only
rehearsal when time permits:

```bash
bash progress/sprint_2/demo/run.sh --rehearsal
```

The rehearsal performs real model inference and creates a new results
directory under `/private/tmp`. It intentionally skips listening, word
corrections, and identity assignment. Its own model outcome can vary. The
final 4 October rehearsal saved 2576 AMI and 802 Sejm timed segments, three
anonymous clusters in each, and no accepted fresh minutes: both 30B
responses failed the quality gate while their transcripts remained saved.
The earlier successful, controlled 30B trial is preserved separately and
clearly labeled when shown. Exit status 0 from the demo means the
walkthrough finished, not that the minutes passed content review.

## Live start

Open the deck on slide 1, open Terminal in the repository root, and run one
command:

```bash
bash progress/sprint_2/demo/run.sh
```

The script creates its own settings and a fresh result store. It stops at
the end of each stage for the Product Owner to inspect the output and ask
questions. Keep that Terminal window open. The script prints the exact
Meeting Review command for a second Terminal window during the operator
stage. If a live inference or the review player fails, show the message and
the retained record; do not replace the live result with a prior file
without naming it as historical evidence.

## Presenter sequence

### Standalone speaker naming for the currently open record

Slide 10 gives this complete block for the Sejm record currently open on
the Sprint 2 Mac. Paste the whole block into Terminal and enter the name
only after verifying the S2 cluster by listening. All required values are
included; the name is read inside the command itself.

```bash
bash -c '
cd /Users/rstyczynski/projects/meeting_minutes
read -r -p "Name for S2: " speaker_name
swift run meeting-summarizer recognize name \
  5C00CCF3-A242-4FB0-845D-92C6D30D7633 S2 "$speaker_name" \
  --store /private/tmp/meeting-sprint2-po-demo.Ry3oFz
'
```

Expected: the same meeting UUID is printed and the entered name is saved
for every S2 segment. Close and reopen Meeting Review to load it. This is
a specific current local record; a new demo creates a different UUID and
store and prints its own complete naming command at stage 4. The
[copyable-command check](../tests/speaker_naming_copyable_command_20261004.json)
executed this block on a temporary copy, changing only the store path.

### Slide-by-slide narration

**Slides 1–4, stage 0 — goal and architecture.** Say: “We wanted a local,
reviewable record from a meeting. Swift owns the durable record and three
separate actions: transcription, optional speaker recognition, and optional
minutes. Parakeet through FluidAudio or Whisper through whisper.cpp recognizes speech.
A separate FluidAudio diarizer analyzes audio to label anonymous voices.
Swift groups the resulting timed parts. MLX/Qwen generates topics and draft
minutes later. The application checks model responses before using them.” Point
out that ASR receives audio and a language selection, whereas the minutes
model receives transcript text and source IDs. Neither output is assumed
correct just because it has valid syntax.

**Slides 5–6, stage 1 — real English and Polish transcription.** Show the
two source paths and let the fresh `transcribe` commands complete. Read the
printed UUID, model revision, language, number of timed segments and
beginning of each transcript. Say: “The words come from actual recordings;
the reference transcripts are not injected. Segment count proves that the
pipeline ran, not that every word is correct.” Show the official Sejm
comparison through the linked [review](../tests/polish_sejm_pdf_transcription_review_20261002.md)
if the Product Owner asks about Polish accuracy. The edited PDF gives a
passage-level check, not a whole-recording Word Error Rate.

**Slide 7, stage 2 — weak audio.** Show the AMI warning ranges from the new
record. Say: “The first affected range is near 19 seconds. The system
warns us to listen; it does not repair the sound.” State the reference
finding: four people spoke in AMI, but the detector formed three clusters
and merged the weak-headset person with another. Show the neutral speaker
IDs and the Sejm result.

**Slides 8–10, stages 3–4 — operator control.** Show the CLI's candidate
joins and its separate reading utterances. Slide 8 depicts the earlier
saved Sejm run at 565.36–569.04 seconds: raw `segment_758`–`segment_761`
were unassigned, while the reading view proposed joining the phrase to
the preceding S1 turn. Fresh segment IDs may differ, so use the fresh CLI
output as the live result and call slide 8 a fixed evidence example. In
the second Terminal, execute the exact `meeting-review` command printed
by the script. Listen to the source range and let the Product Owner see
selection and playback. Only answer `tak` if this actually happened.
The script first attempts a correction **without** audio confirmation on
a disposable copy of the real Sejm record. The CLI must return 2 and the
copy's SHA-256 must stay the same; this is the guard demonstration recorded
in the test evidence. Slide 9 now shows the tools and the actual correction
command as an alternative. Select a phrase in Meeting Review's readable transcript and choose
Correct selection to correct an audibly wrong word, confirm listening and save. The
reading refreshes immediately. Demonstrate Restore original and Cancel;
every saved correction keeps the original ASR and history. The script prints
the saved correction history and offers the CLI route separately. The
[GUI instructions](../user_manual.md#correct-words-inside-meeting-review) and
[copyable CLI steps](../user_manual.md#run-the-correction-in-terminal)
explain both routes. If using the CLI, enter its exact printed segment ID and
replacement after listening.
If there is no verified mistake, press Enter and show that no edit was
made. Explain that a name is assigned only after checking the **whole**
cluster. Given the known AMI merge, leaving names neutral is the expected
safe outcome. Slide 10 now shows the `recognize name` operation explicitly.
Stage 4 asks the operator for the meeting, existing speaker ID and verified
name, prints the complete command with the current UUID and store, executes
it, and shows the saved mapping. A name applies to **every segment in that
cluster**. Close Meeting Review and use the printed exact command to reopen
the record: this prototype reads a snapshot and does not automatically
refresh after a CLI edit. Point out that naming is the operator's decision;
the product does not discover the person's identity. The controlled correction, restore, and CLI guard evidence
linked in slide 9's notes is a test result, not a claim that a human previously listened
to that source. If the player cannot be operated, record that limitation
and continue without asserting audio review.

**Slides 11–12, stage 5 — minutes and response validation.** Run the fresh
30B staged generator on a 120-second AMI excerpt and the ten-minute Sejm
meeting. Show the result saved in JSON, including a zero-item result when
the validator rejects a response. Say: “This run's status is the actual
live outcome. The transcript survives a rejected minutes response.” The
script then prints every topic summary from the **earlier recorded**
successful 30B run. In that controlled run, the model assigned all 21/21
AMI and 32/32 Sejm reading utterances to topics. An independent audit found
only 2/5 AMI and 2/4 Sejm topic summaries fully supported by their own
cited transcript lines. The Sejm run found one of two explicit decision
signals. The confusion between meeting-room equipment and product design
on the AMI slide is a semantic topic error, not a speaker-label error.
The script also prints the earlier Sejm draft from before the current
quality gate: its supported positive-opinion decision sits beside an
unsupported action, invented question and uncited summary. State that
those are historical rejected candidates, not newly generated minutes.
The response gate checks structure, IDs, quotations and bounded repair;
it cannot establish that every paraphrase is true.

**Slides 13–16, stage 6 — broader evidence.** Show the saved 30-minute DOE
result: 4216 timed segments and eight anonymous speaker IDs, while both
tested smaller minutes models saved zero review items. Show the recorded
same-input AMI Word Error Rate comparison: Parakeet v2 19.48%, Whisper base.en 28.79%.
For language feasibility on separate short read-speech clips, Parakeet v3
had 11.49% English and 3.41% Polish Word Error Rate, versus Whisper base on CPU at
18.39% and 27.27%. Do not describe those read-speech scores as Polish
meeting accuracy. The actual recorded benchmark, not the fresh demo run,
produced these scores.

**Slides 19–21 — findings, limits and conclusions.** Say: “The measured results support an executable local
architecture experiment. It preserves timed source text, supports
operator review and reversible edits, and rejects some invalid model
output. Speaker identity and natural-meeting minutes still fail the
required quality bar. We should retain transcript review and staged
source checks, then validate semantic quality with annotated meetings
before treating minutes as publishable.” Invite the Product Owner to
inspect a saved record, request a repeat, and state the handover decision.
Record the actual questions and decision in the
[handover](../sprint_2_handover.md); passing this script does not imply
acceptance.

## Evidence and recovery

The new store path and all three UUIDs are printed at the end and in
`record-ids.txt` inside that store. The JSON files contain the saved source
and output; `cli-stderr.log` holds build and adapter diagnostics. If a
source or model is missing, `--check` reports the exact absent path. If a
model response is invalid, the script prints the adapter error and the
remaining transcript and continues to the recorded comparison. The
[rehearsal record](../tests/po_demo_rehearsal_20261004.md) identifies which
steps were actually executed and which operator actions still require a
person at the Mac.

### Pipeline and configurable reading rules during the live review

On slide 3 follow the numbered processing steps, then on slide 4 explicitly distinguish the ASR, FluidAudio diarizer and Qwen LLM. At stage 3, before listening, show parameter slides 17–18 and the [complete segmentation profile](segmentation-settings.json). The [operator guide](../transcript_segmentation.md) lists every field and a standalone CLI example for the existing demo record. For the new live store, apply the same profile with the fresh UUID; the script already uses resolved defaults saved at transcription.

Explain: speaker changes form boundaries, same-speaker speech joins without a time or silence cap, and unassigned joins are proposals. A changed saved profile invalidates derived minutes. The archived Sejm configuration check gives four turns preserving 802 parts; fresh diarization can produce different labels and block counts. Do not substitute that recorded result for the live output.


### Closing narrative

After the benchmark, show parameter slides 17–18 if they were not already used at the operator stage. Always finish with slides 19–21. On slide 19 summarize the working local transcription/review path, same-input ASR comparison, four-turn reading correction with source conservation, reversible controls and measured 30B memory cost. On slide 20 separate speaker clustering, transcript errors, LLM meaning failures, long-input limits and pending manual playback. On slide 21 explain the validation directions implied by those findings: operator review, human topic/item references, semantic and voice boundary checks, and comparative long-meeting/resource experiments.

The conclusion is that Sprint 2 provides useful architecture evidence while dependable minutes remain unvalidated. These directions inform the already planned Sprint 3 evidence assessment; they do not assign new PBIs or imply Product Owner acceptance. Invite the Product Owner's actual reaction and record it in the handover, then end the presentation. Do not return to parameter slides after the conclusion.


### Selected-text editor live check

On slide 9, select “Szanowni Państwo, tylko poinformuję,” in the Sejm transcript, then choose **Correct selection**. Show the selected range 108.08–109.84 s and independently adjustable before/after context (2 s each initially). Play the requested 106.08–111.84 s range and confirm it is audible and bounded. Edit only an actual verified error, save, inspect range history and refreshed reading, restore and cancel an unsaved edit. Do not enter an invented correction into the real record merely to make the demo pass. If no error is present, use a disposable copy and label the controlled edit explicitly. Run the existing **Source words and correction IDs** view to show raw preservation.

This native interaction was not rehearsed: the QA-window launch was declined. Record the real observed result in the handover; do not substitute the earlier word-editor GUI check. The CLI alternative affects one source part, and rejects source edits inside an active range correction. Range edits and restoration use Meeting Review; multi-stage minutes consumes the same corrected projection. The [manual](../user_manual.md#correct-words-inside-meeting-review) gives the exact steps and limitations.

## Bidirectional synchronization on slide 9

Use the review command printed at stage 3 for the fresh demo, or the [existing-session command](../user_manual.md#synchronize-audio-and-transcript-text). Show **Play** moving the yellow transcript mark and **Pause** stopping audio. Drag **Audio position** across the real Sejm pause from 148.40 to 181.68 s: source marking should disappear in the gap, then reappear on the next S1 card. Selection in one card pauses and moves the slider to the earliest selected source start; Play explicitly resumes. Verify mouse and Shift-arrow selection do not get replaced by the moving playback mark, and active text follows into view.

Show an original timed source first. Then inspect the earlier saved replacement if using the existing session: selecting “sygnał” maps to 134.88 s because its corrected paragraph is one source interval. Explain this precision limit rather than presenting it as replacement-word timing. Continue through Correct selection, context playback, a verified error, Save, Restore and Cancel using the established correction steps. An unperformed listening or scrolling step remains pending in handover. This feature uses the saved transcript; it does not call an ASR or LLM.
