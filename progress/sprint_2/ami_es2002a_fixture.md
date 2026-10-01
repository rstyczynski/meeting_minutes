# Sprint 2 — Approved AMI ES2002a fixture

## Purpose and approval

The Product Owner approved AMI meeting ES2002a as the natural-meeting fixture
for Sprint 2. It is used for the same-audio FluidAudio versus whisper.cpp
benchmark and the FR-09 low-quality-audio experiment. The official
[AMI corpus page](https://groups.inf.ed.ac.uk/ami/corpus/) identifies the
dataset, and the [data-problems page](https://groups.inf.ed.ac.uk/ami/corpus/dataproblems.shtml)
records that one ES2002a participant did not wear the headset microphone
properly. That problem is part of the test condition, not a model result.

## Local files and provenance

All downloaded files and extracted annotations are under
/private/tmp/meeting-minutes-ami, outside the repository and Git. The
[headset mix](https://groups.inf.ed.ac.uk/ami/AMICorpusMirror/amicorpus/ES2002a/audio/ES2002a.Mix-Headset.wav)
and [lapel mix](https://groups.inf.ed.ac.uk/ami/AMICorpusMirror/amicorpus/ES2002a/audio/ES2002a.Mix-Lapel.wav)
are each 40,724,524 bytes, 16 kHz mono 16-bit PCM WAV. The headset mix is the
single input for the engine comparison. The lapel mix is a separate
alternate-input condition for investigating the known headset problem.

Individual Headset-0, Lapel-0, Headset-1, and Lapel-1 WAVs from the same
official directory were also downloaded for channel-level diagnosis. The
[official signal map](https://groups.inf.ed.ac.uk/ami/corpus/signals.shtml)
maps ES2002a channel 0 to manual reference speaker A and channel 1 to B. The
[problem note](https://groups.inf.ed.ac.uk/ami/corpus/dataproblems.shtml)
says "participant 1" wore the headset improperly. That wording does not
by itself establish whether the annotation ID is A or B. The downloaded
official `corpusResources/meetings.xml` entry for ES2002a maps participant
`ES2002a_1` to channel 0 and annotation speaker A. Thus A is the reference
speaker for the documented headset problem. Model error and attribution
still must be scored before claiming that the prototype detects it.

The [official manual annotation archive v1.6.2](https://groups.inf.ed.ac.uk/ami/AMICorpusAnnotations/ami_public_manual_1.6.2.zip)
is 22,887,865 bytes and passed ZIP integrity validation. Extracted
ES2002a references include four speaker-specific word XML files, four
segment XML files, an abstractive summary, a decision-point annotation,
corpusResources/meetings.xml, and LICENCE.txt. The archive's license file
states CC BY 4.0. Attribution: AMI Consortium / University of Edinburgh,
AMI Meeting Corpus, meeting ES2002a, manual annotations v1.6.2.

SHA-256 of the headset mix:
9c76866990fcc8b84006dc32d273ad99df439090b748ebe72103bb78c3216ee7

SHA-256 of the lapel mix:
181765456aa0a81d0fc401a55de804c2df637a2c0a0f23330d541490132d9b11

SHA-256 of individual Headset-1:
285ed5b5eaa4f871cc146900d0cf87487ca757aa57a7062def2eb49feaabc23d

SHA-256 of individual Lapel-1:
99c1a7764bcf9250394fc6db117eafc3b80499b3015efa370ae870ae7d315d06

SHA-256 of individual Headset-0:
3bf0627106d6b6f02e5cc8b69f283b70303275c6b354aef3bdc7a50762d3f25e

SHA-256 of individual Lapel-0:
eadc88cb2887d2d32c344a6b8b61c5a8621156e597a3836a9711d23e7b2bb197

SHA-256 of the manual annotation ZIP:
b56e5babb2496b8795deeeda7e71178d7fbc9963f94276cf2a3f4b56ebbc9f9d

The test-only [reference converter](../../experiments/prepare_ami_reference.py)
created ES2002a/manual_words.json outside Git from the four manual word
files. It contains 2,600 timed, non-punctuation words: 233 for speaker A,
1,300 for B, 82 for C, and 985 for D. The first reference word begins at
50.42 seconds and the last ends at 1109.45 seconds. These counts are
annotation coverage, not a quality score or proof that any one speaker is
the participant with the headset problem. SHA-256 of that derived reference:
eed56446ce306eb3b2d2901fc498476fc408f208ab591d116ae04c9d0b606691

The local regeneration command is:

~~~bash
python3 experiments/prepare_ami_reference.py --annotations /private/tmp/meeting-minutes-ami/annotations --meeting ES2002a --output /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json
~~~

## Preliminary channel diagnostic

The local [energy probe](../../experiments/probe_ami_audio_quality.py) uses
100 ms windows centered in manually annotated words, excluding windows that
overlap another speaker's annotated word. Its RMS readings are signal-level
diagnostics, not speech recognition, intelligibility, or diarization scores.
The commands are reproducible with the local files above:

~~~bash
python3 experiments/probe_ami_audio_quality.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --headset /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Headset-0.wav --lapel /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Lapel-0.wav --speaker A
python3 experiments/probe_ami_audio_quality.py --reference /private/tmp/meeting-minutes-ami/ES2002a/manual_words.json --headset /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Headset-1.wav --lapel /private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Lapel-1.wav --speaker B
~~~

For A, the probe found 152 isolated target windows and 2,049 other-speaker
windows. Median target RMS was 0.00132 on Headset-0 and 0.00714 on Lapel-0;
the corresponding target-to-other-speaker ratios were 6.33 and 3.33. A's
speech is about 5.4 times louder in the lapel track by this measure. For B,
there were 944 target and 957 other-speaker windows. Median target RMS was
0.00798 on Headset-1 and 0.00710 on Lapel-1; the respective separation ratios
were 37.90 and 3.37. These observations support the official metadata's
mapping of the headset issue to A. They do not show whether the mixed audio
causes more word or speaker-label errors for A, whether lapel improves recognition,
or whether the prototype detects a quality problem. Those results require
the planned model runs and reference scoring.

## Measurement boundary

First run both transcription engines on the unchanged headset mix with
identical decoding and text-scoring rules. Report overall and
speaker-specific transcription and attribution results where the manual
reference permits. Investigate whether the pipeline points the operator
to poor-quality regions or the affected neutral speaker ID. Then evaluate
the lapel mix separately to see whether alternate local input improves
or worsens the affected participant's result. The official metadata maps the
problem note's participant 1 to annotation A. Do not treat the
lapel run as another sample in the same-audio engine comparison.

No inference, per-speaker score, or low-quality detection result has been
produced yet. This file records fixture acquisition, integrity, and the
preliminary signal-level probe only.
