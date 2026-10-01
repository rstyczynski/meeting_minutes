# Sprint 2 — AMI ES2002a ASR benchmark evidence

Status: Sprint 2 measurement complete; architecture interpretation remains
for Sprint 3. Paired headset and alternate-input quality, repeated
runtime, process memory, model footprint, reference-assisted speaker-turn,
and exploratory quality-warning results. Process-level disconnected-network
inference passed for staged ASR and diarization models. The prototype now
persists speaker labels and warnings. Independent warning reliability and
minutes quality failed on the tested natural excerpt. This is
PBI-018 measurement evidence, not a Sprint 3
architecture decision.

## Summary for the Product Owner

On the same AMI ES2002a headset recording, the tested FluidAudio/Parakeet
combination transcribed more accurately than the tested whisper.cpp/Whisper
base.en combination: **19.48% versus 28.79% word error rate**. FluidAudio
also had fewer reference-linked errors in the turns of speaker A, whose
headset was documented as poorly worn: **27.78% versus 58.55%**. These
figures describe one English meeting and these particular model sizes and
settings; they do not establish general accuracy across meetings.

The alternate lapel recording improved speaker A's reference-linked rate
for both combinations, to **22.65%** for FluidAudio and **32.91%** for
whisper.cpp, but worsened overall word error rate to **21.95%** and
**32.62%**, respectively. It is therefore a plausible recovery input for
the affected participant, not an automatic improvement for the whole
meeting. An experimental local quality check flagged anonymous speaker
cluster S3 on the headset, which reference evaluation later mapped mainly
to A. Its warning also covered much of speaker C's speech because the
diarizer merged that person, so it is not yet a reliable participant warning.

In three runs on the same 120-second headset excerpt, FluidAudio's median
wall time was **0.73 seconds** and whisper.cpp's was **1.29 seconds**.
FluidAudio's measured process resident memory ranged from 113 to 121 MB,
versus 452 to 454 MB for whisper.cpp. The installed FluidAudio model
directory was larger, about 452 MiB versus 141 MiB for the Whisper model.
The memory figures omit any accelerator allocation not reported as process
resident memory. The separate FluidAudio offline diarizer found only three
speaker clusters against four annotated people. Its reference-aligned
coverage improved for the affected speaker on lapel input but lost some
overall accuracy. Both are practical local ASR candidates, but reliable
speaker labels and dependable poor-audio warnings require further work.
The local MLX minutes experiment below also exposed unsupported claims on
natural speech. Sprint 3 should decide how these findings affect the default.

## Compared model combinations

**FluidAudio 0.17.4 with Parakeet TDT 0.6B v2 Core ML** is the Swift and
Apple-device path. In this experiment it led on transcription accuracy,
affected-speaker errors, measured wall time, and process resident memory.
Its staged model footprint was larger. Its separate offline diarizer missed
one of four reference speakers, so attribution remains a material risk.

**whisper.cpp commit `6e4ab854` with Whisper base.en** is the C/C++ path
invoked through the Swift process adapter. In this experiment its staged
model was smaller, while its transcription error, measured wall time, and
process resident memory were higher. Comparing these two selected model
sizes is an architecture feasibility test, not a model-family ranking.

## Requirement findings and evidence trail

**PBI-018, common-input transcription quality — measured.** Both engines
processed the same unmodified 16 kHz mono mixed headset WAV, identified by
SHA-256 `9c76866990fcc8b84006dc32d273ad99df439090b748ebe72103bb78c3216ee7`.
The 2,633 normalized reference tokens came from AMI's timed manual word
annotations, converted to
`/private/tmp/meeting-minutes-ami/ES2002a/manual_words.json`. The model
outputs are `fluid_headset.json` and `whisper_headset.json` in the same
directory. The scoring commands and normalization are below. Those inputs
produced the 19.48% and 28.79% WER results above. This criterion has
evidence for one meeting; representative accuracy across meetings remains
open.

**PBI-018, cost of local inference — measured on one Mac.** The pinned
120-second WAV excerpt is identified by SHA-256
`250f33db21281d6d8fba7c25aeb39bfc5f9a2f74d649dedec853920f63d1e3ac`.
Six successful output JSON files and six `/usr/bin/time -l` logs named
`fluid_120s_run1` through `run3` and `whisper_120s_run1` through `run3`
are held outside Git in `/private/tmp/meeting-minutes-ami/ES2002a/`.
The per-run times, resident sizes, output segment counts, and model sizes
are reproduced in this report below. This establishes a same-machine,
warm-cache comparison; packaging size and accelerator memory remain open.

**FR-09, warning about unreliable audio — partial experimental detection;
requirement not validated.** Official AMI metadata identifies headset-problem participant
1 as annotation speaker A. Alignment of the two headset transcripts with
that speaker's reference words found 65 errors in 234 tokens for
FluidAudio and 137 in 234 for whisper.cpp, with insertions excluded from
these speaker-linked counts. The local experimental diarizer/energy helper,
without reference input, flagged 16 source ranges for its low-level S3
speaker cluster. Evaluation afterward found those ranges covered 186 of
A's 233 annotated words but missed 47. They also covered 83 words from
other speakers, including 61 of C's 82 because C had been merged with S3.
The lapel run emitted no warning. This is a useful signal but does not
reliably isolate the participant. The prototype persisted the same 16 S3
warning ranges in AMI headset record
`87A64680-FD3C-44D4-9529-039E7071E46A` under
`/private/tmp/meeting-sprint2-real-store`. This proves the warning reaches
the review record; it does not make identification reliable. The
[fixture provenance](ami_es2002a_fixture.md) explains
the reference mapping.

**FR-10, source review and recovery — partial evidence; requirement not
validated.** The original headset WAV remains available. Separate lapel
outputs `fluid_lapel.json` and `whisper_lapel.json` were scored against the
same manual words, showing better speaker-A reference-linked error rates
but worse overall WER. The SwiftUI review app loaded the real AMI record,
showed 16 warnings, and sought to the first warning at 19.3 seconds and
a transcript segment at 4.7 seconds. That manual check also found continuous
playback disruptive, so the player was changed to pause after the selected
range; the bounded replay change builds but has not been manually replayed.
An operator comparison that preserves both derived results remains open.

**PBI-018, speaker attribution — measured with a major limitation.**
FluidAudio's offline diarizer produced `diarization_headset.json` and
`diarization_lapel.json` from the corresponding full meeting recordings.
The [diarization scorer](../../experiments/score_ami_diarization.py) maps
anonymous clusters to reference speakers only after inference, then checks
whether each manual word midpoint has the right label. It found three
predicted speakers for four reference speakers. Headset input correctly
covered 2,219 of 2,600 reference words; lapel input covered 2,200.
Speaker A improved from 186 of 233 words to 206 of 233, while speaker C
had zero correctly attributed words in both conditions. This is a
reference-assisted word-midpoint measure, not standard diarization error
rate or automatic identity recognition. The current product adapter attached
the headset labels and 16 warnings to the real AMI record cited above;
2582 transcript segments were saved after recognition. Three predicted
speaker IDs still represent four reference people, so the stored labels
must not be presented as dependable identities.

**PBI-018, timestamp quality — diagnostic measured.** Exact ASR words were
aligned to timed reference words. Among complete segments with a match,
FluidAudio's median absolute start and end deviations were each 0.07 s;
whisper.cpp's were 0.46 s and 0.51 s. The engines output very different
segment lengths, and the reference envelope is formed only from matched
words, so this is a useful seekability diagnostic rather than a directly
comparable timestamp benchmark. Counts and upper-tail errors appear below.

**PBI-018, local-only inference — passed for staged models on this Mac.**
After staging weights, all three local processes ran the same 120-second
headset sample under a macOS process sandbox that denied networking.
FluidAudio ASR emitted 210 segments, whisper.cpp emitted 28, and FluidAudio
diarization emitted 15. A `curl` control inside that sandbox could not
resolve `example.com`, confirming the network restriction. This verifies
inference without a network service; it does not eliminate the one-time
weight preparation or prove packaging on another device.

**PBI-018, local minutes experiment — measured with a quality failure.**
Xcode 27 and its Metal Toolchain built MLX Swift's shader library. The pinned
MLX Swift LM 3.31.3 adapter loaded locally staged Qwen3-4B-Instruct-2507
4-bit weights (revision `50d427756c6b1b2fe0c0a10f67fbda1fc8e82c1b`;
model SHA-256 `2a73c6c248601ab904e035548abd8e6abb65ea27dcb5f342fb0a8910eb44173f`)
and generated valid, source-linked minutes from the invented
five-turn fixture. The model produced one summary, one decision, one action
with the correct owner ID, and one open question; the CLI persisted all four
in record `8DAAA0BB-C4A0-4863-9198-025E9FD4E643` under
`/private/tmp/meeting-sprint2-mlx-flow`.

The same adapter then processed the first 120 seconds of the approved AMI
headset recording. The first attempt fed 210 word-level segments and produced
truncated JSON with excessive citations. Grouping adjacent words into
short source chunks yielded parseable JSON; the validator expanded citations
back to original transcript IDs. The CLI persisted record
`4604E907-2EE9-4FE6-974A-8D22A5F9914D`. Its summary reasonably identifies
the remote-control kickoff, but the derived decision treats the project goal
as a decision, the two actions propose work not committed in the cited text,
and the two open questions are model-generated rather than questions asked in
the source. Those items are **not trustworthy meeting minutes**. The adapter
discarded an unsupported owner ID instead of assigning it to a person. This
experiment demonstrates local execution and traceable storage, not minutes
quality. The saved JSON is low-level evidence; these findings are the
decision-facing interpretation.

**PBI-018, remaining architecture options — measured limits.** Both ASR
backends return timed segments and local model provenance. The chosen
minutes model passed a small synthetic contract check but failed natural
meeting content quality. Sprint 3 must analyze these results and decide
whether a different model, prompt, chunking strategy, or human review gate
is needed before treating generated minutes as reliable.

## Input and model identity

The two engines processed the same unmodified AMI ES2002a mixed headset
WAV. Its SHA-256 is
`9c76866990fcc8b84006dc32d273ad99df439090b748ebe72103bb78c3216ee7`.
The separate mixed lapel WAV, SHA-256
`181765456aa0a81d0fc401a55de804c2df637a2c0a0f23330d541490132d9b11`,
was used for an alternate-input experiment and is not part of the
same-audio engine comparison. Sources, license, and the official mapping of
the headset-problem participant to annotation speaker A are in
[the fixture record](ami_es2002a_fixture.md).

FluidAudio package version 0.17.4 used the local Parakeet TDT 0.6B v2 Core ML
assets under `/private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v2`.
The Swift package resolves to revision
`21493f8dac5a97e65742e6ff26f42f164c2fda0f`.
whisper.cpp was built from Git commit
`6e4ab854f67f743900934a703d5603419384c961` with Metal, using the
`ggml-base.en.bin` model (SHA-256
`a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002`).
Both output JSON files are outside Git under
`/private/tmp/meeting-minutes-ami/ES2002a/`.

The repeat resource check used a 120-second excerpt of that headset mix,
converted to mono 16 kHz PCM. Its SHA-256 is
`250f33db21281d6d8fba7c25aeb39bfc5f9a2f74d649dedec853920f63d1e3ac`.
This is a runtime sample, not the full-meeting accuracy input. The machine
is Mac16,8 running macOS 26.6.2. Both executable paths and models were
already staged locally when repeat runs began.

## Scoring protocol

The [scoring script](../../experiments/score_ami_transcript.py) uses the
official timed manual word annotations converted by
[the reference converter](../../experiments/prepare_ami_reference.py).
It scores only 50.42–1109.45 seconds, the annotated span, excluding the
unannotated beginning and end. Text is lowercased and tokenized into ASCII
letter or digit runs with internal apostrophes; punctuation is discarded
and hyphens split. The 2,600 timed annotation words become 2,633 normalized
tokens. A segment crossing a scoring-window boundary is included whole, a
small source of boundary error. Overall word error rate is substitutions
plus deletions plus insertions divided by reference tokens. Global word
alignment assigns substitutions and deletions to the reference speaker;
insertions remain unassigned. Thus a speaker's reported
`reference_linked_error_rate` is not a conventional per-speaker WER and does
not assess diarization.

The reproducible scoring commands are:

~~~bash
python3 experiments/score_ami_transcript.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --hypothesis /private/tmp/meeting-minutes-ami/ES2002a/fluid_headset.json
python3 experiments/score_ami_transcript.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --hypothesis /private/tmp/meeting-minutes-ami/ES2002a/whisper_headset.json
python3 experiments/score_ami_transcript.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --hypothesis /private/tmp/meeting-minutes-ami/ES2002a/fluid_lapel.json
python3 experiments/score_ami_transcript.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --hypothesis /private/tmp/meeting-minutes-ami/ES2002a/whisper_lapel.json
~~~

## First full headset results

FluidAudio produced 2,312 normalized hypothesis tokens against 2,633
reference tokens: 132 substitutions, 351 deletions, and 30 insertions.
Overall WER was **0.1948**. Speaker A had 234 reference tokens, 12
substitutions, and 53 deletions, giving a reference-linked error rate of
**0.2778**. Speaker B's corresponding rate was 0.1280, C's 0.2317, and D's
0.2299.

whisper.cpp produced 2,333 hypothesis tokens against the same 2,633
reference tokens: 328 substitutions, 365 deletions, and 65 insertions.
Overall WER was **0.2879**. Speaker A had 53 substitutions and 84 deletions
on the same 234 reference tokens, giving a reference-linked error rate of
**0.5855**. Speaker B's rate was 0.2127, C's 0.4390, and D's 0.2398.

In this first pass, both engines had more reference-linked errors on the
documented headset-problem speaker A than on speaker B. FluidAudio had
lower overall WER than whisper.cpp with these particular model sizes and
settings. This does not by itself establish a preferred production backend:
speaker attribution, quality warnings, minutes, packaging, and broader
hardware repeatability still need evaluation. No prototype
warning for A or its ranges has been produced, so FR-09 and FR-10 are not
validated by these ASR scores.

## Alternate-input result

FluidAudio has also processed the mixed lapel WAV as a separate condition.
Against the same manual annotation window, its overall WER was **0.2195**:
147 substitutions, 404 deletions, and 27 insertions on 2,633 reference
tokens. Speaker A's reference-linked error rate was **0.2265** (17
substitutions and 36 deletions on 234 tokens). For A, this is lower than the
headset's 0.2778, while overall WER is higher than the headset's 0.1948.
Speaker B's rate rose from 0.1280 to 0.1806.

whisper.cpp on the lapel WAV had overall WER **0.3262**: 276
substitutions, 538 deletions, and 45 insertions. Speaker A's
reference-linked error rate was **0.3291** (20 substitutions and 57
deletions), compared with 0.5855 on the headset. Speaker B's rate rose
from 0.2127 to 0.2973. For both engines, the lapel input lowered the
reference-linked error rate for the documented affected participant but
increased overall WER. This is an observation on one meeting, not a proven
recovery strategy. Neither model identified the affected speaker or warned
about poor audio; those acceptance checks remain open. The lapel runs are
separate input conditions, not part of the same-audio engine comparison.

## Speaker attribution experiment

The pinned FluidAudio offline diarizer was run once on each full mixed
recording, separately from the two ASR engines. It emitted 117 headset
speaker-turn segments and 140 lapel segments, but only three anonymous
clusters in each case. The reference has four speakers. The scorer chooses
the one-to-one label mapping that maximizes reference-word coverage; this
uses ground truth solely for evaluation, never as a prototype input. On
the headset it mapped S1 to B, S2 to D, and S3 to A. The same mapping won
for the lapel. Speaker C received no distinct predicted cluster.

For the headset, 2,219 of 2,600 manual word midpoints had a correctly
mapped active diarizer label, 300 had a wrong label, and 81 had no label.
For the lapel, the counts were 2,200 correct, 311 wrong, and 89 uncovered.
The affected speaker A had 186 correct, 31 wrong, and 16 uncovered words
on the headset; lapel changed these to 206 correct, 18 wrong, and 9
uncovered. Speaker C had zero correct out of 82 on both. The alternate
input helps A's attribution under this measure but does not fix the
four-speaker failure. This is not DER or JER: it samples manual word
midpoints, gives credit if any overlapping predicted label matches, and
does not count false alarms outside annotated words. No person name is
generated by this experiment.

The experimental warning rule measures RMS audio level within each predicted
speaker turn lasting at least half a second. It flags all turns belonging
to a cluster whose median turn RMS is below half the median of all cluster
medians. This uses only the audio and predicted anonymous labels. On the
headset, S3's median was 0.001864 against a threshold of 0.002862, producing
16 warning ranges. On the lapel, S3's median was 0.005921 against a threshold
of 0.004147, so no range was warned. The threshold was chosen during this
single-meeting exploration, not validated on an independent corpus.
Against manual annotations, headset warning ranges covered 186/233 A words
and 83/2,367 words from other speakers; C accounts for 61 of those 83.
The warning is reviewable by source range, but its participant identity is
unreliable. It must remain an uncertain range-level cue until speaker
separation improves.

The reproducible checks are:

~~~bash
python3 experiments/score_ami_diarization.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --diarization /private/tmp/meeting-minutes-ami/ES2002a/diarization_headset.json
python3 experiments/score_ami_diarization.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --diarization /private/tmp/meeting-minutes-ami/ES2002a/diarization_lapel.json
~~~

## Timestamp diagnostic

The [timing scorer](../../experiments/score_ami_timing.py) aligns exact
recognized words to the manual timed words, then compares each complete
hypothesis segment's start and end with the envelope of its matched
reference words. FluidAudio had 2,147 segments with an exact match among
2,308 complete segments. Its median absolute start and end deviations were
0.07 s each; 90th-percentile deviations were 0.18 s and 0.33 s. whisper.cpp
had 365 matched segments among 424 complete segments. Its medians were
0.46 s and 0.51 s; 90th percentiles were 1.43 s and 1.65 s. FluidAudio
emits mostly word-sized segments, while whisper.cpp emits longer phrases.
The scores therefore show the precision of the current adapter outputs for
seeking, not a controlled comparison of identical boundary types. Only
exact matched words in segments wholly inside the annotation window count;
omissions and false words have no timing score.

~~~bash
python3 experiments/score_ami_timing.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --hypothesis /private/tmp/meeting-minutes-ami/ES2002a/fluid_headset.json
python3 experiments/score_ami_timing.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --hypothesis /private/tmp/meeting-minutes-ami/ES2002a/whisper_headset.json
~~~

## Resource measurements

Each engine ran the same 120-second headset excerpt three times in sequence
using the same model and default inference settings as its full-meeting run.
The `/usr/bin/time -l` wall times for FluidAudio were 0.79, 0.73, and 0.68
seconds; its maximum resident sizes were 113,377,280, 119,767,040, and
120,848,384 bytes. whisper.cpp wall times were 1.46, 1.29, and 1.25 seconds;
maximum resident sizes were 453,640,192, 453,033,984, and 451,723,264
bytes. Median wall times were 0.73 and 1.29 seconds, respectively. Each
FluidAudio run produced 210 segments and each whisper.cpp run produced 28,
so neither timing is an empty-run artifact. Per-run JSON and `time` logs are
under `/private/tmp/meeting-minutes-ami/ES2002a/` with names
`fluid_120s_run1` through `run3` and `whisper_120s_run1` through `run3`.

The local compiled FluidAudio model directory occupies 462,596 KiB on disk;
the whisper.cpp `ggml-base.en.bin` file is 147,964,211 bytes (148,112 KiB
allocated on disk). These sizes describe the staged inference assets, not
an installer or total application. The measurements are warm-cache results
on one Mac. macOS process resident size may omit accelerator memory, so this
is a process-memory comparison rather than a total device-memory claim.

## License and local operation evidence

The pinned [FluidAudio SDK](https://github.com/FluidInference/FluidAudio/blob/main/LICENSE)
uses Apache 2.0. Its [converted Parakeet model card](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml)
states CC BY 4.0. The pinned
[whisper.cpp source](https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE)
uses MIT, and the [converted Whisper model collection](https://huggingface.co/ggerganov/whisper.cpp)
is marked MIT. The staged executables completed the measured runs using
local model paths without a download step. A process-level
disconnected-network check passed as detailed below; packaging attribution
review is still pending.

## Disconnected-network check

The one-time model downloads were completed before this check. macOS
`sandbox-exec` applied `(version 1) (allow default) (deny network*)` to
each inference process without changing system-wide connectivity. As a
control, `curl -I --max-time 3 https://example.com` under the same profile
exited 6 because it could not resolve the host. Under that profile, the
staged FluidAudio ASR, whisper.cpp ASR, and FluidAudio offline diarizer
each exited 0 on the 120-second headset WAV. Their outputs were parsed as
JSON and contained 210, 28, and 15 segments, respectively. Files named
`fluid_offline`, `whisper_offline`, and `diarization_offline` (JSON and logs)
are under `/private/tmp/meeting-minutes-ami/ES2002a/`. This establishes
local inference with prepared weights on this Mac; it does not test a fresh
installation with no assets or an iOS package.
The separately built MLX minutes adapter also exited 0 under the same
network-denial profile on the invented five-turn transcript and produced
parseable JSON with cited decision, action, and open-question IDs in
`/private/tmp/meeting-mlx-synthetic-offline.json`. This establishes local
LLM inference after staging its weights and Metal shader library; it does
not repair the natural-meeting content failure described above.

## Remaining checks

Timed transcript segments and the limited exact-match timing diagnostic
exist for both engines. The offline diarizer's anonymous labels and
exploratory audio-level warnings now reach a saved prototype record, but
the warning fails reliable participant isolation. The review player sought
to selected source ranges; bounded playback and alternate-input comparison
need further operator checking. Packaging license obligations still need
verification. The local MLX generator executed on synthetic and natural
transcripts; the natural minutes failed content quality. Those failures are
the measured inputs to the Sprint 3 architecture review.

## PBI-018 acceptance assessment

Both ASR options used the same pinned headset audio and the same manual
reference, normalization, and scoring code. The separate lapel recording
was labeled as a recovery condition, not mixed into that comparison.
The four WER scores, two reference-assisted diarization scores, and two
timestamp diagnostics were reproduced from stored outputs during the Sprint
2 completion check and matched this report. Repeated runtime, memory, model
footprint, license, input hashes, executable revisions, and measurement
limits are stated above. The natural-minutes failure and the warning
spillover are measured outcomes, not missing measurements. This satisfies
PBI-018's requirement to preserve a reproducible comparison for Sprint 3;
it does not approve a default ASR, a dependable participant warning, or an
unattended minutes generator.
