# Transcript segmentation — operator controls

## Which component does what?

Parakeet ASR through FluidAudio produces recognized words and token timings; the adapter creates timed word parts. The Whisper adapter supplies timed fragments, which are not necessarily individual words. These are source parts, not finished conversational turns.

The separate FluidAudio offline diarizer analyzes the recording and assigns anonymous voice clusters such as S1, S2 and S3. A cluster label distinguishes a predicted voice; it is not a person's name. The operator can assign a name with `recognize name`. Diarization can merge different people incorrectly, as the AMI benchmark demonstrated.

Swift's `TranscriptCleaner` builds a reversible reading layer from timed parts, operator text corrections and those speaker labels. By default, a change of labeled speaker creates a boundary, consecutive parts from the same speaker join, and a gap of at least `longSilenceBoundarySeconds` starts a new segment even for the same speaker. No elapsed-duration cap applies by default. Neighbor assignments for unassigned parts are proposals displayed for review. Source text, labels and timestamps are preserved. The local Qwen LLM receives the prepared utterances later, when generating topics and minutes; it does not perform this joining.

## Every segmentation control

The [complete example profile](demo/segmentation-settings.json) contains all eleven controls under `transcriptCleanup`. Every control below can be changed in JSON. The values listed here are defaults, not fixed thresholds inside the algorithm. A partial profile inherits defaults. Unknown keys and invalid values are rejected.

1. `grouping`: `speakerTurns` (default) joins eligible consecutive parts of the same effective speaker; `sourceParts` shows each source part separately. Neighbor proposals remain visible in either mode.

2. `mergeUnassignedSegments`: `true` groups consecutive parts still lacking a speaker. Set `false` to retain individual unassigned parts. It does not turn an unknown speaker into a known one.

3. `proposeNeighborSpeakers`: `true` enables the reversible neighbor assignment heuristic. Set `false` to group using original diarization labels only, retaining operator text corrections.

4. `preserveSpeakerChanges`: `true` prevents the heuristic from overriding a labeled part, even a one-word S2 turn between S1 parts. `false` enables the earlier brief-switch proposal experiment. This setting does not change the raw labels.

5. `maximumCandidateWords`: `1` identifies short text candidates using whitespace-separated words. A positive integer greater than one includes longer brief-switch candidates when that experiment is enabled. Unassigned continuations near just one neighbor can be examined regardless of word count.

6. `maximumNeighborGapSeconds`: `1.5` is the largest temporal separation considered near a neighbor for an assignment proposal. It does not split a same-speaker reading turn. Valid values are finite and nonnegative.

7. `maximumOverlapSeconds`: `0.15` is the largest allowed overlap between a candidate and its neighbor. A negative measured gap means overlap. Valid values are finite and nonnegative.

8. `maximumOneSidedGapSeconds`: `0.5` limits a join proposal supported by just one labeled neighbor. It must be finite, nonnegative and no greater than `maximumNeighborGapSeconds`. A bridge supported by the same labeled speaker on both sides uses the neighbor limits instead.

9. `maximumReadingBlockSeconds`: `null` disables a duration cap. A positive finite number requests a maximum block span, checked before appending a source part. A source part is never truncated even if it alone exceeds the cap. There is no default 15-second split.

10. `maximumReadingGapSeconds`: `null` disables this optional stricter gap cutoff; the long-silence boundary remains active. A finite nonnegative number explicitly requests a boundary at a larger gap between consecutive parts. There is no default 1.5-second reading split.

11. `longSilenceBoundarySeconds`: `10` seconds by default. A gap **greater than or equal to** this finite positive value starts a new segment, including S1 followed by S1. Missing or null values in old profiles resolve to 10. It measures separation between timed source parts; it is a prototype temporal rule, not automatic topic discovery. Set a different positive value in JSON to adjust it.

Speaker equality is the basis of the `speakerTurns` grouping mode. Source identity, valid timestamps, nonempty text and conservation of every source part are mandatory data invariants. They are not optional thresholds. This profile controls the reading layer; ASR decoding, diarization model internals and minutes generation have separate settings and limits.

## Apply the profile and inspect a real meeting

The following complete block uses the existing Sejm demo record on the Sprint 2 Mac. The WAV need not be transcribed again. The checked-in profile initially selects the defaults above; edit it to try a different reading policy.

```bash
cd /Users/rstyczynski/projects/meeting_minutes
swift run meeting-summarizer configure-cleanup \
  5C00CCF3-A242-4FB0-845D-92C6D30D7633 \
  --settings progress/sprint_2/demo/segmentation-settings.json \
  --store /private/tmp/meeting-sprint2-po-demo.Ry3oFz
cat /private/tmp/meeting-sprint2-po-demo.Ry3oFz/5C00CCF3-A242-4FB0-845D-92C6D30D7633.json | jq '.transcriptCleanupPolicy'
swift run meeting-summarizer inspect-cleanup \
  5C00CCF3-A242-4FB0-845D-92C6D30D7633 \
  --store /private/tmp/meeting-sprint2-po-demo.Ry3oFz | jq -r \
  '.utterances[] | "[\(.range.startSeconds)–\(.range.endSeconds)s] \(.speakerID // "Unassigned") (\(.sourceSegmentIDs|length) source parts):\n\(.text)\n"'
```

Expected: the first command prints the same UUID. The stored profile has `grouping: speakerTurns` and `preserveSpeakerChanges: true`; absent optional numeric fields mean the optional caps are disabled; a missing long-silence field still resolves to 10 seconds. Inspection now shows five reading segments accounting for all 802 raw parts; the first S1 segment ends at 148.40 s and the next S1 segment begins at 181.68 s. The measured 33.28-second pause exceeds the 10-second threshold; the amount `35 779` and the S3 phrase `zadania związane z organizacją` each stay in one turn. This is source-preserving grouping evidence, not proof that those recognized words are accurate. The [current receipt](tests/long_silence_review_20261004.json) and [output](tests/reading_blocks_long_silence_20261004.json) record execution on a disposable copy; the earlier [four-turn receipt](tests/cleanup_configuration_20261004.json) is historical. No test changed the live record.

Changing a saved profile clears derived minutes, topics and their coverage because their utterance IDs may have changed. Raw transcription, speaker names and recorded operator corrections remain saved. Reapplying the same profile preserves current derived results. Restart Meeting Review to load the changed profile. Multi-stage `summarize` uses the saved profile; a different ASR/model settings file does not silently replace it. Legacy single-pass minutes do not use this reading layer.

New `transcribe` records persist the profile supplied by their settings file, or the resolved defaults. Old records without a profile use current defaults until explicitly configured. To reproduce historical reading groupings use their captured evidence or an explicit historical profile; a replay under current defaults is a new reading result.

## Current quality boundary

Using diarization labels to separate voices is implemented. Reassessing voice identity from audio at each boundary and checking semantic continuity are not implemented. Neighbor proximity alone is a hypothesis; inspect the proposed joins and listen to the recording. Long uninterrupted same-speaker speech can still form long blocks by default, which may warrant later topic or sentence boundaries. Do not restore an arbitrary time cutoff to claim those boundaries were validated.

## Audio-position inspection

Meeting Review and its correction sheet show **Audio position**, current seconds and total duration. Drag the slider to pause and choose a position; releasing seeks. **Play** in the main view or **Play from position** in the correction sheet resumes from there. This cancels the earlier bounded fragment request. Use **Play selection with context** to start bounded playback again. The same player and position are shared by both views. The control is disabled until media duration is available. Native audio/slider verification is pending; automatic gates built the native component but did not listen.
