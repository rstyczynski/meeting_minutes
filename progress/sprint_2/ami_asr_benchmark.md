# Sprint 2 — AMI ES2002a ASR benchmark evidence

Status: Preliminary paired headset and alternate-input quality, repeated
runtime, process memory, and model footprint results. Speaker-attribution,
quality-warning, timing-error, and disconnected-network checks remain
pending. This is PBI-018 measurement
evidence, not a Sprint 3 architecture decision.

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
meeting. Neither prototype path currently detects the affected participant
or marks audio ranges for review.

In three runs on the same 120-second headset excerpt, FluidAudio's median
wall time was **0.73 seconds** and whisper.cpp's was **1.29 seconds**.
FluidAudio's measured process resident memory ranged from 113 to 121 MB,
versus 452 to 454 MB for whisper.cpp. The installed FluidAudio model
directory was larger, about 452 MiB versus 141 MiB for the Whisper model.
The memory figures omit any accelerator allocation not reported as process
resident memory. Both are practical local ASR candidates, but the
speaker-label, poor-audio-warning, timing, offline, and minutes checks must
be finished before recommending a default in Sprint 3.

## Compared model combinations

**FluidAudio 0.17.4 with Parakeet TDT 0.6B v2 Core ML** is the Swift and
Apple-device path. In this experiment it led on transcription accuracy,
affected-speaker errors, measured wall time, and process resident memory.
Its staged model footprint was larger. FluidAudio also offers diarization,
but this prototype has not yet measured its attribution quality.

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

**FR-09, warning about unreliable audio — fails current prototype
validation.** Official AMI metadata identifies headset-problem participant
1 as annotation speaker A. Alignment of the two headset transcripts with
that speaker's reference words found 65 errors in 234 tokens for
FluidAudio and 137 in 234 for whisper.cpp, with insertions excluded from
these speaker-linked counts. This proves the participant is an important
accuracy case; it does not prove automatic detection. Neither prototype
output names an affected speaker or flags a suspect source range. Thus no
warning coverage, missed-region rate, or false-warning rate can yet be
reported. The specific reference and limitation are recorded below and
in the [fixture provenance](ami_es2002a_fixture.md).

**FR-10, source review and recovery — partial evidence; requirement not
validated.** The original headset WAV remains available. Separate lapel
outputs `fluid_lapel.json` and `whisper_lapel.json` were scored against the
same manual words, showing better speaker-A reference-linked error rates
but worse overall WER. The current prototype has not demonstrated
range-level replay or an operator comparison that preserves both derived
results. The ASR measurement alone cannot pass FR-10.

**PBI-018, remaining architecture options — pending.** Both backends return
timed segments and local model provenance. Speaker-attribution accuracy,
word or segment timing error, disconnected-network operation, and LLM
minutes quality have no completed measurements. PBI-018 cannot be marked
complete until these are measured or explicitly reported as blocked in the
Sprint 2 quality review. Sprint 3 will analyze the completed evidence for
an architecture recommendation.

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
local model paths without a download step. This confirms local-path
inference, but an explicit disconnected-network run and any packaging
attribution review are still pending.

## Remaining checks

Timed transcript segments exist for both engines, but boundary timing error
against the manual annotation and speaker attribution have not yet been
scored. The prototype has not emitted FR-09 warnings or demonstrated FR-10
replay and recovery. Actual disconnected-network operation and packaging
license obligations also need verification. No minutes-quality result is
available because the current real-model path has no minutes generator.
