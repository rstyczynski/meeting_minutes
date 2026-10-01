# Sprint 2 — Proposed changes

## FR-11 — Add English and Polish validation to Sprint 2

Status: Sprint scope and PBI-011.6 design accepted by the Product Owner on
2026-10-01. The Product
Owner asked why the prototype lacked language control and directed FR-11 into
the current sprint. The root plan and SRS now include the two-language
validation objective. The accepted design adds an explicit language option,
multilingual local model variants, common referenced English/Polish audio,
quality and resource measurements, and failure behavior. The existing
English-only benchmark remains valid for its measured scope, but it cannot
demonstrate Polish support. The prior documentation approval request is
superseded by this new work. PBI-011.6 has since implemented the language
option and both multilingual candidates; the observed measurements and
remaining gaps are in the [benchmark](ami_asr_benchmark.md).

## PBI-011 — Separate transcription, optional recognition, and optional summary

Status: Accepted by the Product Owner on 2026-10-01. The three-command
contract and named tests now amend the accepted Sprint 2 design.

This is a cross-sprint change because the resulting CLI requirements revise
the Sprint 1 SRS. The impact and possible targeted redo of earlier baseline
work are recorded in sprint_2_setup.md under Cross-sprint requirements
impact. Earlier sprint artifacts and statuses are not changed by this
proposal.

The Product Owner specified three CLI capabilities named transcribe,
recognize, and summarize. Recognize and summarize are independent optional
operations after transcription. Recognize supports chair-controlled
assignments or corrections; automatic name suggestions are a nice-to-have
requirement beyond the MVP. This accepted amendment replaced the original
single-import prototype flow. The legacy import route remains for early test
compatibility. Actual operation and limitations are in the
[implementation record](sprint_2_implementation.md).

Proposed CLI contract: transcribe a local recording with an explicit
transcription backend, producing a durable record ID with timed transcript
segments, neutral speaker IDs, and model provenance, but no minutes:

~~~text
meeting-summarizer transcribe <local.wav> --transcriber fluid|whisper [--settings settings.json] [--store directory]
~~~

The optional recognize command aligns voice turns to the transcript. The
chair may assign or correct names for speaker IDs in the review app or
through CLI commands. A later nice-to-have version may suggest names from
local media or supplied voice references; it cannot infer a person's
identity from diarization alone. Manual assignments are authoritative.
The proposed diarization form and the optional correction forms are:

~~~text
meeting-summarizer recognize <record-id> --diarizer fluid [--settings settings.json] [--store directory]
meeting-summarizer recognize name <record-id> <speaker-id> <display-name> [--store directory]
meeting-summarizer recognize move <record-id> <segment-id> <speaker-id> [--store directory]
~~~

If recognize is skipped, transcript segments retain neutral or unknown
speaker labels, and summarize must still work. The diarization form does not
automatically assign a person's name.

An automatic name-suggestion command and its evidence sources belong to the
deferred nice-to-have FR-08. Sprint 2 needs to validate the manual naming
boundary and the model-independent record contract, not select an identity
discovery method.

The summary command works whether or not recognize ran. It uses assigned
names where available and otherwise retains neutral labels such as
speaker_2; it never invents a person's identity. Detailed dependency,
rerun, and stale-summary behavior will be defined in a later iteration
from prototype evidence. Automatic suggestions, if implemented later, must
retain their evidence and uncertainty and must not be presented as
chair-confirmed names.

Meeting minutes become a separate command, explicitly selecting the minutes
generator. It reads the saved transcript and any assigned speaker names,
generates source-linked summary, decisions, actions, and open questions, and
atomically updates the same record. It does not transcribe the audio again:

~~~text
meeting-summarizer summarize <record-id> --summarizer mlx [--settings settings.json] [--store directory]
~~~

The summarize command runs with neutral labels when names have not been
assigned. It fails explicitly if the selected local LLM or model weights are
missing.
Synthetic tests may use a fixture generator through a test-only option, but
its output must be labeled as fixture-derived. A real meeting summary cannot
be claimed from the synthetic fixture path.

The revised CLI test specification covers transcribe producing only a
transcript; recognize diarization and chair edits preserving the same record;
summarize after recognition using assigned names; and summarize without
recognition using neutral labels. It must test missing media, unknown record,
missing local model, invalid speaker or segment ID, and an invalid source
reference. Functional sequences show actual commands and inspect the
saved JSON, not infer success from a zero exit code alone. Their executed
results are in the [functional test record](sprint_2_tests.md).

Separating commands and adding chair-controlled names refines PBI-011.2,
PBI-011.3, PBI-011.4, and PBI-011.5 within Sprint 2. Automatic identity
matching is now an optional functional requirement in the SRS, outside the
initial MVP; its product priority and sprint assignment remain for later
backlog planning. The accepted design, test specification, Swift contracts,
CLI, review UI, functional test instructions, and implementation record need
revision for the independent commands. Existing test cases should cover
transcription alone, summary using neutral labels, and summary using
chair-assigned names, without treating later workflow policy as a Sprint 2
acceptance gate. The PBI-018 benchmark must measure ASR and minutes
separately so errors can be attributed to the correct capability.

## PBI-018 — Validate low-quality participant audio

Status: Accepted in the Sprint 2 design on 2026-10-01

The Product Owner made low-quality audio a critical Sprint 2 validation
requirement and added FR-09 and FR-10, with two explicit use cases, to the shared SRS. The approved AMI meeting
ES2002a is a concrete natural fixture because its official data-problems
record identifies a participant with a poorly worn headset microphone.
The original mixed-headset WAV and manual annotations are stored outside
Git. A mixed-lapel WAV from the same meeting provides a separate
alternate-input condition; it must not be mixed into the same-audio
FluidAudio versus whisper.cpp comparison. The official ES2002a meeting
metadata maps the documented participant 1 headset problem to manual
annotation speaker A. Individual microphone tracks and manual annotations
are evaluation references only; the prototype must detect suspect regions
from its normal mixed-recording input without being given that answer.

Run both ASR engines on the same headset mix first. Align their timed output
and speaker turns with the manual reference, and report errors for the
affected participant separately from the other speakers when the reference
mapping permits it. Inspect whether the pipeline flags degraded audio at
the participant or region level and whether those flags direct the operator
to the relevant source range. Compare the lapel mix as a separate recovery
condition and record whether it improves or harms transcript and
attribution quality. Preserve the original and report ambiguous mappings,
unintelligible reference regions, elapsed time, memory, and limitations.

The experiment passes the participant-recognition check only if the pipeline
produces a reviewable warning tied to the affected neutral speaker or its
source ranges, and the reference alignment shows that the warning covers
speaker A's degraded speech. Record missed A regions and warnings on other
speakers, without relabeling uncertain regions as A. If the models or
prototype cannot produce this warning, report FR-09 as failing validation
with the measured transcription and attribution results; a human reading
the AMI metadata is not system detection.

Sprint 2 must produce measurements and an explicit conclusion about whether
the candidate architecture can expose and handle this risk. Production
thresholds, final preprocessing policy, and detailed recovery behavior are
deferred to Sprint 3 analysis and requirements refinement.
