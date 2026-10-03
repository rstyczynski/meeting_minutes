# Sprint 2 — AMI ES2002a ASR benchmark evidence

Status: initial English measurement complete; FR-11 bilingual extension measured;
architecture interpretation remains
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

## FR-11 language coverage audit — the original English-only variants

The Product Owner's [FR-11](../../docs/srs.md) requires English and Polish transcription. The Product Owner added two-language validation and explicit language control to Sprint 2. The original Fluid adapter used Parakeet TDT 0.6B **v2**. [FluidAudio's ASR documentation](https://github.com/FluidInference/FluidAudio/blob/main/Documentation/ASR/GettingStarted.md) calls v2 English only. The original whisper.cpp weight was `ggml-base.en.bin`; [Whisper's model documentation](https://github.com/openai/whisper/blob/main/README.md) lists `base.en` as English only. Consequently neither originally benchmarked model supports required Polish transcription by its documented capability. The AMI scores above are English-only evidence.

Source-supported candidate variants were identified before the new increment. [NVIDIA's Parakeet v3 model card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) lists English and Polish among its 25 languages, and FluidAudio publishes a [v3 Core ML conversion](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml). Whisper publishes multilingual `base` separately from `base.en`, and [whisper.cpp recognizes `pl`](https://github.com/ggml-org/whisper.cpp/blob/master/src/whisper.cpp). At the time of this source audit, the helper was fixed to v2 and the product adapters had no language option. The subsequent PBI-011.6 work added both controls and measured the new variants below.

The original English results alone did not validate FR-11. The following
extension is a separate comparison of different model variants on different
speech data; do not combine its percentages with the AMI model ranking above.

## FR-11 bilingual extension — PBI-011.6 and PBI-018

**Decision-facing result.** Both new local adapters produced English and
Polish transcripts through the product's `transcribe --language` command.
On the same five English FLEURS clips, Parakeet v3 made **10 errors in 87
reference words (11.49% WER)**, versus multilingual Whisper base's **16 in
87 (18.39%)**. On the same five Polish clips, Parakeet v3 made **3 errors in
88 words (3.41%)**, versus Whisper's **24 in 88 (27.27%)**. Unicode character
error rates, excluding spaces, were **2.65% versus 7.51%** for English and
**0.88% versus 7.36%** for Polish. These are ten short read-speech clips,
not meetings; no production accuracy threshold is established. The saved
[per-clip results](tests/fr11_fleurs_results.json) contain every reference,
hypothesis, score, runtime, requested language, model revision, SHA-256, and
record ID. [Input provenance](tests/fr11_fleurs_manifest.json) identifies
all ten audio clips.

**Runtime and footprint.** End-to-end product CLI times include a fresh
model load for each clip. Parakeet v3 took a median **6.18 s** per English
clip and **6.27 s** per Polish clip. Whisper base took **0.46 s** and
**0.51 s** respectively in CPU mode. These times are useful startup
observations, but the accelerators differ and the tiny clips are unsuitable
for sustained-throughput ranking. The staged v3 Core ML directory uses
about **470 MiB**; `ggml-base.bin` is **147,951,465 bytes** (about 141 MiB).
Whisper's Metal execution asserted during model initialization in this
environment (`GGML_ASSERT(buffer)`), before any audio was decoded. Explicit
`whisperUseGPU: false` in settings passed `-ng` and allowed all ten CPU runs.
This is a packaging/Metal risk for the multilingual Whisper candidate, not
an observed recognition error. The earlier base.en AMI timing and memory
numbers are for a different model and must not be reused for this comparison.

**Reproducibility and rights.** The [FLEURS dataset](https://huggingface.co/datasets/google/fleurs)
validation rows 0–4 for each of `en_us` and `pl_pl` were fetched through
Hugging Face's dataset server. The reported dataset revision is
`70bb2e84b976b7e960aa89f1c648e09c59f894dd`; no audio conversion was
used in the separate-language scores. The ten downloaded WAVs, source URLs,
clip IDs, bytes, exact reference text, and SHA-256 hashes are in the manifest.
FLEURS is licensed CC BY 4.0. The large WAVs and model weights stay outside
Git under `/private/tmp/meeting-fr11-fleurs/` and
`/private/tmp/meeting-minutes-models/`. Both language subsets include source
gender classes 0 and 1, confirming voice diversity, but no verified speaker
IDs are supplied. This does not establish a multiple-speaker Polish meeting
result. The earlier AMI experiment remains the English meeting and
poor-audio evidence. At the time of this paired experiment, representative
Polish meeting audio had not yet been run. The later Sejm run is described
below; a scored reference is still needed before an architecture default
can be selected.

The new Fluid adapter uses FluidAudio 0.17.4 at revision
`21493f8dac5a97e65742e6ff26f42f164c2fda0f` and Parakeet TDT 0.6B v3
Core ML. Its local model folder is
`/private/tmp/meeting-minutes-models/parakeet-tdt-0.6b-v3`; the encoder
weight file SHA-256 is
`d48034a167a82e88fc3df64f60af963ab3983538271175b8319e7d5720a0fb86`.
The [upstream v3 conversion](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml)
and [original model](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)
both identify CC BY 4.0. The Whisper comparison uses whisper.cpp commit
`6e4ab854f67f743900934a703d5603419384c961` and multilingual
`ggml-base.bin` SHA-256
`60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe`;
the [published model repository](https://huggingface.co/ggerganov/whisper.cpp)
identifies MIT. Artifact hashes fix the exact tested bytes where upstream
release tags can move.

**Scoring and traceability.** The [fetcher](../../experiments/fetch_fleurs_subset.py)
stages the fixed subset; the [runner](../../experiments/benchmark_fleurs.py)
calls the real product CLI, verifies input checksums, reloads each persisted
record, and computes Levenshtein word and character error. It applies Unicode
NFKC, casefolding, and punctuation removal while preserving Polish letters;
CER excludes spaces. The ten references contain 87 English and 88 Polish
words, or 453 and 571 nonspace characters. English per-clip Fluid WER values
were 0%, 15.15%, 14.29%, 20%, and 0%; Whisper's were 6.67%, 21.21%, 0%,
80%, and 0%. Polish Fluid values were 2.70%, 0%, 6.67%, 0%, and 11.11%;
Whisper's were 24.32%, 20%, 33.33%, 16.67%, and 55.56%. The one high
Whisper English error clip contains a proper name and unfamiliar word; the
sample is too small to infer general language behavior from it. All 20
product records persisted the requested language and model name.

**Offline and mixed-language checks.** With networking denied at the
macOS process level, the product CLI successfully created Polish records
`41A894A8-2063-4F59-AC1B-9F42FB603754` (Whisper CPU) and
`58B80C7C-80EA-4B1B-AD01-73878D446E26` (Fluid v3) from the same staged
clip. This verifies local inference for those variants on this host.
In a separate one-clip-per-language check, `auto` reproduced each backend's
explicit-language transcript on the selected English and Polish clips; the
four saved [auto results](tests/fr11_auto_results.json) show the requested
language, model, text, and scores. This establishes a basic single-language
auto route, not a trustworthy language detector across meetings. An
exploratory `en` then `pl` concatenation was made from two of the licensed
WAVs with ffmpeg (SHA-256
`ad6bcf724aeefa4814d96ccaa8d8bf23158fdfb409ce9338f3152a1295a1acf7`).
With `--language auto`, both engines returned only the Polish sentence and
omitted the preceding English sentence. The saved [Fluid](tests/fr11_mixed_fluid_record.json)
and [Whisper](tests/fr11_mixed_whisper_record.json) records show this
failure. The splice is artificial and exploratory, but it rules out a claim
that `auto` currently handles a language switch within one recording.

**Assessment.** PBI-011.6 demonstrates explicit language selection,
English-only model rejection, persisted language/model provenance, and
working English and Polish local transcription. The paired PBI-018 extension
provides comparable small-sample quality, runtime, footprint, offline,
license, and failure evidence. Parakeet v3 led on this subset, while
Whisper base had a Metal load failure and required CPU mode. Neither result
selects the production model. Polish meeting reference scoring,
independently verified speaker mapping, mixed-language handling, larger
varied sets, and production quality thresholds remain for Sprint 3 analysis
and later validation.

After the Product Owner rejected read-speech clips as meeting demo material,
the prototype transcribed and diarized a ten-minute excerpt from an
[official Polish Sejm committee meeting](polish_sejm_meeting_fixture.md).
Parakeet v3 saved 802 timed segments and the diarizer saved three anonymous
speaker IDs. The official written record supports identifying the chair on
the opening turn, but it is edited and not time aligned. Therefore this
additional real meeting test does not add a Polish whole-meeting WER or a
speaker-attribution accuracy score to the paired benchmark. The minutes
path initially rejected an invalid model citation. After a structural
repair it saved draft items, but a false action and invented open question
remain; the [test record](sprint_2_tests.md#polish-multi-person-meeting-correction--2026-10-02)
contains the evidence. These are reasons to withhold a minutes-quality
decision, not to revise the ASR comparison scores.

## Remaining checks

### Polish meeting minutes quality check

Before evaluating minutes, the Sejm ASR output was checked against the
[official full sitting PDF](https://api.sejm.gov.pl/sejm/term10/committees/GOR/sittings/39/pdf).
The [passage-level review](tests/polish_sejm_pdf_transcription_review_20261002.md)
aligns the formal opening through the start of the PKN presentation, about
181–600 seconds of the ten-minute excerpt, with PDF pages 4–5. The saved
transcript follows the chair's opening, minister's budget presentation,
positive-opinion decision, and next-speaker handoff. Several important
amounts and the decision are recognizable. It also contains material
word/name/acronym errors and malformed or ambiguous numeric units: `Witwa`
for `Witam`, `Panie Mistrze` for `Panie ministrze`, `Polsca` for `POLSA`,
`CIDG` for `CEIDG`, and `28` where the PDF has agenda points 2–8. The
34,662,000-thousand-złoty amount ends in a truncated ASR unit. This is
useful but not authoritative transcription; a reviewer must correct it
before treating it as the meeting record. The PDF is polished, omits
pre-meeting speech, and is not time aligned, so no whole-excerpt WER or
speaker-attribution score is claimed. This reference-backed review
corrects the earlier overly broad statement that Polish meeting ASR
quality had not been assessed at all.

The Sejm excerpt adds a real, ten-minute Polish multi-person input to the
minutes experiment. The fixed input is the 599.997-second WAV with SHA-256
`1045d5199ea673b56c63f77c02a59b9a6be7c2887f1922253c887e2f93f184b9`.
Parakeet v3 produced 802 timed segments; Fluid assigned three speaker IDs.
The minutes generator used local MLX Swift LM with staged
Qwen3-4B-Instruct-2507 4-bit weights. The source and exact run identity are
in the [fixture record](polish_sejm_meeting_fixture.md) and [run
capture](tests/polish_sejm_meeting_run_20261002.json).

The first model output cited `S1`, a speaker label, as a source segment ID.
The prototype's strict validator rejected it with status 2 and persisted
zero items. That is a structural integration failure, independent of
whether any sentence was accurate. The repaired `minutes-v2` adapter
distinguishes source IDs from speaker IDs, retries once on invalid IDs, and
keeps an action owner only if cited segments include that speaker. On the
same input, the CLI then exited 0 and persisted four draft items. The
structural path passed a focused regression test and the six Sprint gates.

Content was checked item by item against the cited transcript range and
the official written sitting record. The positive-opinion decision at
about 540–553 seconds is supported by the chair's words. The model also
called a request to present the next budget an action and generated an
open question absent from the cited 288–296 second source. The summary has
no source citation. Thus one of the three non-summary items is supported
and two fail this manual source review; this is a four-item case study, not
a population estimate. The draft must not be published. A stronger prompt
requesting summary citations was also tried on the same input; it changed
to English and added unsupported budget details, so that experiment was
reverted. At that comparison the tested adapter remained `minutes-v2`;
the later approved evidence-first gate is assessed below.

From an architecture perspective, this evidence shows that valid JSON and
valid segment IDs are insufficient measures of minutes quality. The
current 4B model and prompt do not meet a reliable source-grounded minutes
bar on this real meeting. Sprint 2 cannot select it as the default
unattended minutes generator or claim the increment ready for delivery.
The next comparison needs a fixed set of real multi-person meetings in
English and Polish, item-level human source review, unsupported-item and
missed-item counts, language fidelity, citation validity, runtime, and
memory. The Product Owner has identified the present defect as a delivery
blocker. This finding does not change the paired Fluid/Whisper ASR scores.

To test whether a larger compatible model removes the problem, the same
Sejm record was copied to a separate store and run through the same
`minutes-v2` adapter with
[Qwen2.5-7B-Instruct-4bit](https://huggingface.co/mlx-community/Qwen2.5-7B-Instruct-4bit)
at revision `c26a38f6a37d0a51b4e9a1eb3026530fa35d9fed`. Its staged
`model.safetensors` is 4,284,346,255 bytes, SHA-256
`86110f368236b53cf4c2336f991a85703b17bcc60bb75f292b4002ec0219f071`;
the 4B baseline file is 2,263,022,417 bytes. The 7B run exited 0 and
saved a summary, decision, and action. The summary switched to English.
The decision's cited range ended near 533 seconds, before the chair's
positive-opinion conclusion near 540 seconds, and the action again
misclassified a transition to the next budget item. No open question was
invented, but neither non-summary item passed manual source review. This
single controlled comparison does not establish that model size predicts
meeting-minutes quality. The alternative was not promoted to the product
default.

A second, longer English fixture comes from the [U.S. Department of Energy
advisory committee recording and speaker-labeled
transcript](doe_itiac_day2_fixture.md). The first 30 minutes produced 4,216
timed English segments and eight anonymous speaker IDs. On this identical
saved transcript, both the 4B and 7B minutes attempts exited with status
2 while parsing model output and persisted zero review items. The [English
run capture](tests/doe_itiac_day2_run_20261002.json) records the exact
errors. This tests longer real multi-person input rather than substituting
short speech. The DOE transcript is not time aligned, so this additional
fixture does not add a defensible whole-excerpt ASR WER. Taken together,
the Polish and English cases show that neither tested local minutes model
is ready for a dependable default. They also expose a length-related
structured-output risk requiring focused follow-up; the two cases alone
do not prove that length caused the parse failures.

### Evidence-first gate and larger local model candidate

The approved `minutes-v3-evidence` adapter now requires parseable JSON,
bounded item counts, existing source IDs, and exact quotations in the
cited chunks. It sends at most two specific repair prompts and rejects
unrepaired output before MeetingCore can save it. Controlled tests and all
six Sprint gates pass. On the same real AMI and Sejm inputs, however, the
4B model still failed technical or content review; 7B found part of the
Sejm decision wording but did not cite the entire quote. This improves
failure containment, not minutes quality. The [test
record](sprint_2_tests.md#evidence-first-minutes-and-response-gate--2026-10-02)
lists the observed failures.

The local Mac has an M4 Pro, 48 GB unified memory, and 51 GiB free at the
start of this feasibility check. The [Qwen3-30B-A3B-Instruct-2507 model
card](https://huggingface.co/Qwen/Qwen3-30B-A3B-Instruct-2507) identifies
30.5B total parameters, 3.3B active parameters, and multilingual
instruction following. Its [MLX 4-bit
conversion](https://huggingface.co/mlx-community/Qwen3-30B-A3B-Instruct-2507-4bit)
has 17,181,071,994 bytes of weight shards (about 16 GiB). [MLX Swift LM
lists `qwen3_moe` as a supported
architecture](https://github.com/ml-explore/mlx-swift-lm/blob/main/skills/mlx-swift-lm/references/supported-models.md).
This makes a local trial plausible within the Mac's storage and memory,
but it was not a measured runtime or quality pass at selection. On 2026-10-03 all 16
files of the pinned revision were downloaded into the local Git-ignored
`.models/qwen3-30b-a3b-instruct-2507-4bit/` directory. The four shard
sizes and SHA-256 hashes match repository metadata; the [download
evidence](tests/qwen3_30b_download_20261003.md) gives exact values.

**30B same-input result.** The [controlled trial](tests/qwen3_30b_minutes_trial_20261003.md)
used the same 217-segment AMI and 801-segment Sejm transcripts, the same
`minutes-v3-evidence` prompt and bounded validator, and a separate clean
store. AMI exited 0 in **11.97 seconds** with **9.77 GB** maximum resident
set size reported by `/usr/bin/time -l`. After one citation repair it
saved one exact, cited quotation of the remote-control design brief and
no decision, action, or question. That is technically grounded, but it
does not demonstrate useful minutes. Sejm exited 2 in **26.32 seconds**
with **17.33 GB** reported maximum resident set size; its three identical
responses omitted the closing bracket of `decisions`, so the validator
withheld all review items and preserved the transcript. Even a mechanical
JSON repair would leave a misspelled decision quotation whose cited
`source_73` ends before the quoted words in `source_74`. The Polish summary
quotes an incomplete opening sentence. Both run logs, all raw attempts,
saved records, transcript identity checks, and source review are linked
in the trial. The memory figures are host process observations, not
isolated GPU allocation; no comparable timed 4B/7B run under this exact
setup was captured, so a speed ranking would be unjustified.

The 30B model improves a narrow AMI citation result but fails the Polish
technical and content checks. Neither the 4B, 7B, nor 30B candidate has
established dependable local minutes on this two-meeting review set.
The larger model is not promoted to the product default. Sprint 3 must
assess the model, prompting and human-review workflow using item-level
correctness, missed items, citation coverage, language fidelity, runtime,
and memory on more representative meetings.

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
