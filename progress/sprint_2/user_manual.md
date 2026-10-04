# Meeting Summarizer user manual

## Synchronize audio and transcript text

Close the old Meeting Review window so it releases its previous executable, then relaunch the updated build for the current session. This command opens the application; it does not start sound. The temporary store and original audio must still exist on this Mac.

```bash
cd /Users/rstyczynski/projects/meeting_minutes
swift run meeting-review 5C00CCF3-A242-4FB0-845D-92C6D30D7633 --store /private/tmp/meeting-sprint2-po-demo.Ry3oFz
```

Drag **Audio position**: the position previews matching transcript text in yellow and follows it into view. Release to commit the paused seek, then press **Play**. The mark advances with the media clock. Native blue text selection remains available separately for correction; playback does not replace it.

Try the known Sejm pause: at 150–170 s there should be no yellow source text. The preceding S1 card ends at 148.40 s; the next begins at 181.68 s with “Witwa serdecznie” in the uncorrected source. At 181.68 s its source part should be marked. Select that word or a phrase in the second card: audio pauses and the slider moves to the first selected source start. There is no autoplay. You can then Play, or choose **Correct selection** and use contextual playback before saving a verified correction.

Precision follows the stored source. Original Parakeet word parts can be marked individually; a multiword ASR fragment marks together. An already corrected range marks as one span: selecting “sygnał” in the earlier corrected paragraph seeks to its available source start, 134.88 s. The product cannot recover new timestamps for replacement words. The sidebar explains this coarser timing; gaps without source parts stay unmarked. Overlapping source speech can produce more than one mark.

Empty selections do not seek. Invalid/whitespace-only selections show an error; unavailable duration disables the slider. A failed seek reports its error and does not change transcript storage. Save rebuilds the mapping for the updated reading; external CLI edits still require reopening the app. Automated mapping/storage tests cover these rules; real sound/highlight alignment, native selection and scrolling remain pending live verification. [Evidence and limits](tests/transcript_audio_sync_review_20261004.json) are separate from sprint acceptance.

## Selected-text correction and remaining live check

The Product Owner rejected the first word-sized editor because its audio was too brief to hear. The approved repair now offers phrase selection and configurable audio context. Automated mapping, storage and regression tests cover this implementation. The owner session now contains a successful crossing edit ([receipt](tests/selection_owner_session_20261004.json)). Slider seeking, actual audible bounds, keyboard selection, Restore/Cancel and restart still need a live check: the separate QA-window launch was declined, so no new native-UI pass is claimed. [BUG-6](sprint_2_bugs.md#bug-6-word-sized-correction-playback-is-too-short-for-operator-review) remains open for this verification.

## Long silence and audio slider

A 33.28-second gap after “zaczynamy” now starts a second S1 segment: the first ends at **148.40 s**, the next begins at **181.68 s**. The app shows why that boundary was created. The configurable threshold is `transcriptCleanup.longSilenceBoundarySeconds`, default **10 seconds**, positive and finite. The [segmentation guide](transcript_segmentation.md) shows the complete settings file and `configure-cleanup` command. Older files without this setting inherit 10; the previous 15-second duration cap remains disabled.

In the main window and correction sheet, drag **Audio position** to inspect the pause. The displayed value is current time / recording duration in seconds. Dragging pauses and cancels the current bounded fragment; release to seek, then click **Play** or **Play from position**. To replay the selected range with context, click **Play selection with context** again. Missing/invalid duration disables the slider and displays an error. Native slider listening is a pending live check.

Close the running review window and relaunch the updated executable for your existing session:

~~~bash
cd /Users/rstyczynski/projects/meeting_minutes
swift run meeting-review 5C00CCF3-A242-4FB0-845D-92C6D30D7633 --store /private/tmp/meeting-sprint2-po-demo.Ry3oFz
~~~

Expected after relaunch: separate S1 cards across 148.40–181.68 s, preserved “sygnał - od razu zaczynamy.”, and the slider in both views. The named temporary store must still exist on this Mac.

## What the prototype does

The macOS CLI creates a timed transcript from a local WAV recording and saves
it as JSON on the same Mac. You may then run speaker labeling, enter a name
after listening, correct a speaker assignment, and request draft minutes.
`transcribe`, `recognize`, and `summarize` are separate commands. The last two
are optional. A review app opens the same record and seeks to selected
transcript, warning, or source ranges.

The prototype supports `--language en`, `pl`, or `auto`. The validated inputs
now include an English AMI meeting and a ten-minute excerpt of a real Polish
Sejm committee meeting. The English meeting has a documented weak headset.
The [benchmark](ami_asr_benchmark.md)
reports quality against reference transcripts and explains the observed
speaker and minutes failures. The [Polish meeting source](polish_sejm_meeting_fixture.md)
documents its provenance. A [comparison with the official sitting
PDF](tests/polish_sejm_pdf_transcription_review_20261002.md) finds
recognizable meeting turns and decision content alongside transcription
errors; it does not yield a whole-clip word error rate.
An additional [30-minute U.S. Department of Energy committee
meeting](doe_itiac_day2_fixture.md) is staged as a longer English test.
Its transcription and speaker labeling ran, but both tested local minutes
models failed to save review items on the full excerpt. It is test
evidence, not an example of working long-meeting minutes.

## Prepare this Mac

Use a Mac with Swift, Xcode, Metal Toolchain, and `jq`. From the repository
root, follow the [walkthrough preflight and settings
steps](sprint_2_implementation.md#product-owner-walkthrough--real-local-models).
They check the staged audio, model weights, and adapter executables, then
create two settings files and set `store_dir` in the current Terminal
session. The AMI audio, Sejm audio, and weights live under `/private/tmp`
and are outside Git. The settings paths are concrete for the Sprint 2 Mac.
If a preflight file is absent, the implementation record links its source
and model preparation instructions. A fresh checkout does not package all
models or the MLX shader library.

## Live demo starting state

During handover, use the staged real audio, models, and settings from the
preflight above. In that same Terminal session, switch to a new empty store
before running steps 1–4:

~~~bash
store_dir="$(mktemp -d /private/tmp/meeting-sprint2-handover.XXXXXX)"
printf 'Fresh store: %s\n' "$store_dir"
~~~

Each step below shows the saved JSON state immediately after the command.
The Polish excerpt contains several speakers; the weak-audio check uses the
AMI meeting. The historical 4B evidence-first minutes gate rejects the
tested natural-audio output and leaves the transcripts intact. The newer
30B multi-stage experiment saves source-linked draft topics, but its
[manual quality review](tests/multistage_minutes_trial_20261004.md) finds
unsupported claims. The
[handover record](sprint_2_handover.md) reports the rehearsal and pending
Product Owner walkthrough.

## 1. Transcribe English and Polish

After the setup above, run these commands in the same Terminal session:

~~~bash
english_id="$(swift run meeting-summarizer transcribe /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Mix-Headset.wav --transcriber fluid --language en --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir")"
polish_id="$(swift run meeting-summarizer transcribe /private/tmp/meeting-polish-gor-20241016-10min.wav --transcriber fluid --language pl --settings /private/tmp/meeting-owner-polish-settings.json --store "$store_dir")"
cat "$store_dir/$english_id.json" | jq -r '"English: \(.segments|length) segments; \(.modelRevision)"'
cat "$store_dir/$polish_id.json" | jq -r '"Polish: \(.segments|length) segments; \(.modelRevision)", ([.segments[:120][].text] | join(" "))'
~~~

The verified runs produced 2,576 English segments with Parakeet v2 and 802
Polish meeting segments with Parakeet v3. The Polish transcript includes the
chair opening the sitting. A nonempty transcript is not an accuracy result.
The official Polish sitting record is edited and not time aligned. Its
[passage-level comparison](tests/polish_sejm_pdf_transcription_review_20261002.md)
finds recognizable main turns and errors in names, acronyms, words, and
numerical units. The numeric [benchmark scores](ami_asr_benchmark.md)
cover an English meeting and separate single-speaker language data, not
this Polish meeting. Parakeet v2 and Whisper `base.en` reject Polish. The tested
multilingual Parakeet v3 and Whisper `base` accept it. An exploratory
English-to-Polish recording lost its English portion under `auto` with both
backends.

## 2. Review weak audio and speaker labels

Run speaker labeling on both meetings. The saved JSON contains anonymous
IDs and ranges to review in the source audio.

~~~bash
swift run meeting-summarizer recognize "$english_id" --diarizer fluid --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
cat "$store_dir/$english_id.json" | jq -r '"Warnings: \(.qualityWarnings|length)", (.qualityWarnings[:5][] | "  \(.speakerID // "unknown") at \(.range.startSeconds|floor)s: \(.reason)")'
swift run meeting-summarizer recognize "$polish_id" --diarizer fluid --settings /private/tmp/meeting-owner-polish-settings.json --store "$store_dir"
cat "$store_dir/$polish_id.json" | jq -r '"Polish speaker IDs: \([.segments[].speakerID // empty] | unique | join(", "))", "Polish warnings: \(.qualityWarnings|length)"'
~~~

The verified run saved S1, S2, and S3 labels and 16 warnings for low speech
level, beginning near 19.3 seconds. The affected participant was merged
with another speaker in S3. A warning is a cue to listen; it does not repair
the audio or reliably identify a person. The optional review app can open
the record and seek to a selected warning. Its most recent bounded playback
change has build coverage but has not been manually replayed.
The Polish meeting saved S1, S2, and S3 and no weak-audio warnings. These
are speaker clusters, not verified identities or an accuracy score.

## 3. Review audio before naming or moving a speaker

The chair must establish an identity by listening and checking the full
cluster, not by naming one introduction. The AMI run merged four reference
people into three clusters, so no AMI cluster receives a participant name
in the current live journey. The official Sejm PDF identifies its chair on
particular turns but does not verify every segment of S1. That cluster
also remains neutral. The earlier `S2 = Ada (demonstration alias)` run
showed that the CLI can save a name; it was a test alias and is excluded
from the current identity demonstration.

Open the Sejm record in a separate Terminal window so the review app can
remain visible while the CLI is used. The Transcript pane groups the raw
word-timed source parts into readable utterances. Expand **Source words and
correction IDs** on an utterance to inspect or play a precise word range for
an operator correction. A displayed speaker join is a proposal until checked
against audio. Select the source range near 565–569 seconds, play the short
range, and pause or close the app after listening. Its latest bounded-stop
behavior still needs a human replay check. The developer could build and
start the app but could not attach to its window in the 4 October rehearsal,
so no successful listening is claimed there.

~~~bash
swift run meeting-review "$polish_id" --store "$store_dir"
~~~

Only after checking the audio should the chair use `recognize name` for a
verified cluster, or `recognize move` for a segment that belongs to an
already existing speaker ID. The latter cannot create a fourth cluster
to repair the AMI merge. The [operator-review rehearsal](tests/operator_review_rehearsal_20261004.md)
separates tested edit contracts from the still-pending real-audio action.

## Review and correct transcript words

Before asking for minutes, inspect the reversible reading view for short
unassigned fragments and listen to the affected source audio in Meeting
Review. The command below prints candidate joins, their neighboring
segment IDs, and the resulting utterances; it does not change the saved
raw transcript.

~~~bash
swift run meeting-summarizer inspect-cleanup "$polish_id" --store "$store_dir" | jq '{candidates: .candidates, utterances: [.utterances[] | {id, speakerID, text, sourceSegmentIDs}]}'
~~~

The saved real Sejm record yields 16 join proposals and 32 reading
utterances. Raw `segment_758` through `segment_761` are unassigned from
565.36 to 569.04 seconds, with the words “przedstawienie tej tego
budżetu.” The reading view places them with the preceding S1 turn as
`utt_30`. That is a proposal from timing and neighboring labels; confirm
it against audio before trusting the speaker attribution. The [saved CLI
output](tests/operator_cleanup_rehearsal_20261004.json) contains the
original IDs and proposal reasons.

If a word is wrong, `transcribe correct` takes the meeting ID, exact
segment ID, and audio-checked replacement text, followed by
`--audio-reviewed yes`, `--store`, and an optional note. It saves an audit
entry and leaves the original ASR segment untouched. A later correction
can restore the original words; both entries remain in the record. Every
correction clears older draft minutes so the operator must regenerate
them from the current reading view. The CLI rejects a correction without
the audio-reviewed flag and leaves the record unchanged, as the
[rehearsal](tests/operator_review_rehearsal_20261004.md) shows. The
positive before/after and undo path has passing controlled tests, but has
not been exercised against an audio-verified real meeting. The
[implementation record](sprint_2_implementation.md#prototype-conclusion-what-the-minutes-experiment-teaches-us)
explains why this review is needed.

### Correct words inside Meeting Review

Select a phrase by dragging over the readable transcript text, or place the caret and use Shift with the arrow keys. Select within one speaker-turn card. Click **Correct selection** on that card. The editor shows the selected words, surrounding text, original wording and source time range. For example, select “Szanowni Państwo, tylko poinformuję,” at the beginning of the Sejm transcript; the available source interval is 108.08–109.84 seconds.

Set **Audio before (s)** and **after (s)**, initially two seconds each. Click **Play selection with context**. This example requests 106.08–111.84 seconds: 5.76 seconds of context instead of a 1.76-second phrase alone. Listen and use **Pause** when needed. The player waits for seek completion and stops using media time. Settings apply in the current window; reopening uses the two-second defaults. Context is clamped to the recording start/end. Negative or nonfinite context and an invalid source range produce a visible error.

Enter only the replacement for the selected phrase, check **I listened to this source audio**, then **Save correction**. Surrounding words remain unchanged, original ASR remains saved, and obsolete draft minutes/topics are cleared. The reading refreshes immediately after saving. The confirmation records your assertion; it cannot establish that you actually listened.

Save is disabled without confirmation, for blank or unchanged text. **Cancel** discards unsaved input. To restore a saved range, select its replacement, reopen **Correct selection**, listen and confirm, then choose **Restore original**. Selecting text inside or across an existing replacement keeps your exact selected words as the edit target. Saving expands only the storage anchors and preserves the unselected words. Restore adds a history entry. It restores the wording before that range edit, including any earlier single-source correction, without deleting raw ASR or history.

A selection spanning separate speaker-turn cards or noncontiguous fragments is unsupported. Correct each turn separately. A selection crossing existing corrections saves one combined event and retains prior events in history. The editor displays the complete original source range that Restore would reset. Disjoint edits are supported, including inside one multiword source part. A completed external text/profile/speaker edit makes an earlier selection stale; the app rejects it rather than changing the wrong words. Reopen the record and select again. Do not write to the same record simultaneously from independent processes.

ASR timing limits the audio resolution: selection inside a multiword source part plays that part's available interval, plus context. Newly entered words inherit the selected source range; the product does not invent individual word timestamps. A reading-profile change that would split an active range correction is rejected before save; restore the range before changing those boundaries.

The saved record's `transcriptRangeCorrections` array contains ordered source IDs, character anchors, original and replacement words, source range, confirmation time and restoration entries. It is separate from historical single-source `transcriptCorrections`. From the earlier manual steps, inspect it with:

~~~bash
cat "$store_dir/$polish_id.json" | jq '{rangeCorrections: [(.transcriptRangeCorrections // [])[] | {sourceSegmentIDs, originalText, correctedText, sourceRange, audioReviewedAt, restored}], draftItemsRemaining: (.reviewItems | length)}'
swift run meeting-summarizer inspect-cleanup "$polish_id" --store "$store_dir" | jq -r '.utterances[] | "[\(.range.startSeconds)–\(.range.endSeconds)] \(.text)"'
~~~

A saved correction adds one history event; restore adds another, and old draft items are empty until regenerated. Inspection and the multi-stage minutes adapter receive the same corrected reading. Actual listening and native selection remain live validation steps.

### Run the correction in Terminal

The existing CLI corrects one source part; it does not submit the new phrase selection. Use a second Terminal. An edit inside an active range correction is rejected: edit or restore that range in Meeting Review first.
The following commands use `polish_id` and `store_dir` from the
earlier transcription steps. After listening, enter the exact ID displayed
under **Source words and correction IDs** and the words you actually heard.
Do not use the displayed reading-utterance ID in place of a source segment ID.

~~~bash
printf '%s\n' 'Source segment ID from Meeting Review:'
IFS= read -r segment_id
printf '%s\n' 'Corrected words verified against the audio:'
IFS= read -r corrected_text
swift run meeting-summarizer transcribe correct \
  "$polish_id" "$segment_id" "$corrected_text" \
  --audio-reviewed yes --store "$store_dir"
~~~

Run this only after checking the recording. `--audio-reviewed yes` records
your confirmation; it cannot prove that listening occurred. A successful
command prints the meeting UUID. Inspect the saved result:

~~~bash
cat "$store_dir/$polish_id.json" | jq --arg sid "$segment_id" '{original: [.segments[] | select(.id == $sid) | {id, text}], correctionHistory: [(.transcriptCorrections // [])[] | select(.segmentID == $sid) | {originalText, correctedText, audioReviewedAt}], draftItemsRemaining: (.reviewItems | length)}'
~~~

The original text remains unchanged, the history includes the new words,
and old draft minutes are cleared. After an external CLI edit, close and
reopen Meeting Review to load the updated reading. In-app saves refresh
automatically. To restore the source wording, repeat the correction
command using the original text shown above; this saves another history
entry. Regenerate minutes after finishing the corrections. CLI storage and
restore behavior are verified by controlled tests; a real-audio correction
still requires the live operator check.

## 4. Inspect draft minutes

The tested natural-audio minutes path uses a 120-second AMI excerpt. It
creates a separate record, runs the local MLX model, and shows the result.
Recognition adds neutral labels; the invented demonstration alias is not
copied to this record or passed to the minutes model. `summarize` can also
run without recognition.

~~~bash
short_id="$(swift run meeting-summarizer transcribe /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Headset.120s.wav --transcriber fluid --language en --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir")"
swift run meeting-summarizer recognize "$short_id" --diarizer fluid --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
swift run meeting-summarizer summarize "$short_id" --summarizer mlx --pipeline legacy --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
cat "$store_dir/$short_id.json" | jq -r '"Transcript retained: \(.segments|length) segments", "Draft items: \(.reviewItems|length)"'
~~~

The shown 4B setup is a historical evidence-first comparison. The
explicit `--pipeline legacy` selects it. The 4B trial returned a
validation error and left zero draft items.
The saved transcript remains available for review. In an earlier
`minutes-v2` rehearsal, three items were saved, but one question added a
remote-control meaning to the source's “this thing,” another added
inferred setup context, and the summary had no citation. That historical
draft failed content review. The full meeting has not been validated for
minutes quality.

The same local 4B model was attempted on the ten-minute Polish meeting. Its
first run returned `Unknown source segment: S1` with exit status 2. That
structural error was repaired; a historical rerun saved four draft items.
Its decision near 540–546 seconds was supported, while an invitation to
speak was mislabeled as an action and an open question was not asked in its
cited 380–387 second range. The summary had no source citation. The active
validator rejects the new candidate instead of saving those items. The
current command and its JSON check are in the
[implementation walkthrough](sprint_2_implementation.md#4-generate-and-inspect-minutes).

The current CLI default is `--pipeline multi-stage`. The controlled 30B
candidate saved five AMI topic summaries and four Sejm topic summaries
plus one candidate decision from the same saved ASR inputs. Its exact
settings, run script, output records, costs, and source-level faults are
in the [staged trial report](tests/multistage_minutes_trial_20261004.md).
Read those summaries as drafts. Only two summaries in each meeting passed
the report's strict citation audit; neither draft is ready to send to
participants. A fresh 30B live-demo command needs its model and Metal
shader library staged as described in the implementation record.

## Other behavior and recovery

The JSON record retains the original media path, timed transcript, requested
language, model revision, neutral speaker labels, chair names, warning
ranges, and draft review items. The review app reads the same record and can
seek to the original audio. FluidAudio and whisper.cpp are configurable ASR
backends. After model staging, the measured inference paths ran without
network access.

If the CLI prints `Media file does not exist`, check the WAV path and rerun
the preflight. The verified missing-file case returned status 2 without
creating a record. If it reports a missing model, check the settings path
and staged adapter or weights. If Polish is rejected, select a multilingual
variant. Multilingual Whisper failed to load with Metal on this Mac; its
tested CPU setting worked. Keep the existing record when a step fails and
inspect the error before trying another backend.

The [implementation walkthrough](sprint_2_implementation.md#product-owner-walkthrough--real-local-models)
contains the full expected output and limitations. The [functional test
record](sprint_2_tests.md) contains synthetic contract
tests separately from the real-model evidence. The [handover
record](sprint_2_handover.md) records the demonstration
checks and Product Owner decision.

## Configure how transcript parts form readable turns

[Transcript segmentation](transcript_segmentation.md) gives a complete copy-paste command for the current Sejm record and enumerates all eleven JSON controls. `configure-cleanup` stores the profile for CLI inspection, Meeting Review and multi-stage minutes. By default, a labeled speaker change starts a new turn; a pause of at least `longSilenceBoundarySeconds` (10 s by default) also starts a new segment with the same speaker. Short pauses can join; there is no default duration cap. Unassigned neighbor joins remain proposals to verify against audio. Restart the review app after a configuration change. A changed profile clears derived minutes so that old utterance IDs cannot be mistaken for current ones.

If an older saved replacement itself spans a newly requested boundary, the profile operation rejects it rather than guessing which words belong on each side. Temporarily configure a larger positive long-silence threshold that contains that range, reopen the review and restore the affected replacement; then apply the intended profile and correct each segment separately. After upgrading an older record to the current reading defaults, regenerate derived minutes before relying on its utterance IDs.
