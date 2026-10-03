# Sprint 2 — readable meeting transcriptions

These files show the actual timed ASR text saved by the product. They are
rendered from the linked JSON records without running the models again or
correcting recognition errors. Each line gives the time range and the
anonymous speaker label stored with those words. `Unassigned` means that
the diarizer did not attach a speaker ID to that segment. These labels do
not establish the participants' identities.

The [full English AMI ES2002a meeting](ami_es2002a_full.md) contains 2,582
timed segments from Parakeet v2 with speaker assignment. The
[120-second AMI excerpt](ami_es2002a_120s.md) contains 217 timed segments
used in the minutes model comparison. The [ten-minute Polish Sejm committee
excerpt](sejm_gor_10min.md) contains 801 timed segments from Parakeet v3.
The Sejm excerpt begins with speech at 01:48; the earlier part of that WAV
contains no saved transcript segments. For interpretation against the
official edited proceedings, see the [passage-level review](../polish_sejm_pdf_transcription_review_20261002.md).

The full DOE meeting record mentioned in the [test evidence](../doe_itiac_day2_run_20261002.json)
is no longer present in the local store or this repository, so its 4,216
transcript segments cannot be displayed here. The short FLEURS clips and
mixed-language splice are ASR probes rather than meetings and are not
presented as meeting transcripts.

Regenerate these views from their saved JSON records with
[`experiments/export_transcript.py`](../../../../experiments/export_transcript.py).
