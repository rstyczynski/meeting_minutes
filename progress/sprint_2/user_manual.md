# Meeting Summarizer user manual

Status: Sprint 2 architectural prototype. The handover and Product Owner
documentation approval are pending. These instructions describe behavior
that ran locally on the Sprint 2 Mac; this is not a release guide.

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
AMI meeting. The current evidence-first minutes gate rejects the tested
4B output on these recordings and leaves the transcripts intact. Earlier
drafts contained unsupported English interpretation and false Polish
action and question items; they remain historical failure evidence. The
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

## 3. Demonstrate a manual name entry

The chair must establish an identity by listening or using meeting context.
This example saves a deliberately invented demonstration alias for S2; it
does not assert the identity of an AMI participant. The Polish S1 label is
left neutral: the official PDF identifies the chair on particular turns,
but the complete S1 cluster has not been verified.

~~~bash
swift run meeting-summarizer recognize name "$english_id" S2 'Ada (demonstration alias)' --store "$store_dir"
cat "$store_dir/$english_id.json" | jq -r '.speakerNames | to_entries[] | "\(.key) = \(.value)"'
cat "$store_dir/$polish_id.json" | jq -r '"Polish named speakers: \(.speakerNames|length)"'
~~~

The fresh handover record says `S2 = Ada (demonstration alias)` on AMI and zero named
speakers on the neutral Sejm record. An earlier rehearsal named Sejm S1
from the opening turn, but that name applied to the full unverified
cluster, so that operation was removed from the live journey. In an actual meeting,
enter only a name the chair has verified. `recognize move` can reassign a
wrongly labeled transcript segment to an existing speaker ID. The prototype
does not automatically identify people from their voices.

## 4. Inspect draft minutes

The tested natural-audio minutes path uses a 120-second AMI excerpt. It
creates a separate record, runs the local MLX model, and shows the result.
Recognition adds neutral labels; the invented demonstration alias is not
copied to this record or passed to the minutes model. `summarize` can also
run without recognition.

~~~bash
short_id="$(swift run meeting-summarizer transcribe /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Headset.120s.wav --transcriber fluid --language en --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir")"
swift run meeting-summarizer recognize "$short_id" --diarizer fluid --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
swift run meeting-summarizer summarize "$short_id" --summarizer mlx --settings /private/tmp/meeting-owner-english-settings.json --store "$store_dir"
cat "$store_dir/$short_id.json" | jq -r '"Transcript retained: \(.segments|length) segments", "Draft items: \(.reviewItems|length)"'
~~~

The active 4B trial returned a validation error and left zero draft items.
The saved transcript remains available for review. In an earlier
`minutes-v2` rehearsal, three items were saved, but one question added a
remote-control meaning to the source's “this thing,” another added
inferred setup context, and the summary had no citation. That historical
draft failed content review. The full meeting has not been validated for
minutes quality.

The same local model was attempted on the ten-minute Polish meeting. Its
first run returned `Unknown source segment: S1` with exit status 2. That
structural error was repaired; a historical rerun saved four draft items.
Its decision near 540–546 seconds was supported, while an invitation to
speak was mislabeled as an action and an open question was not asked in its
cited 380–387 second range. The summary had no source citation. The active
validator rejects the new candidate instead of saving those items. The
current command and its JSON check are in the
[implementation walkthrough](sprint_2_implementation.md#4-generate-and-inspect-minutes).

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
