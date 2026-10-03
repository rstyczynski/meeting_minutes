# Polish multi-person meeting validation source

The Product Owner rejected single-speaker read-speech clips as a meeting demo.
Sprint 2 therefore added an actual Polish committee sitting to the test
material. The source is [Komisja Gospodarki i Rozwoju, sitting 39 on 16 October
2024](https://api.sejm.gov.pl/sejm/term10/committees/GOR/sittings/39), with an
[official recording entry](https://api.sejm.gov.pl/sejm/term10/videos/518331A64B2ACCCDC1258BB20032D02B)
and [official full sitting record](https://api.sejm.gov.pl/sejm/term10/committees/GOR/sittings/39/pdf).
The recording entry identifies a committee meeting from 12:04 to 12:35.
The written record identifies the chair, Ryszard Petru, opening the sitting;
Ignacy Niemczycki presenting the budget; and Ewa Zielińska speaking later.
The ten-minute audio excerpt contains those speaker turns. This is a real
meeting recording, not a constructed concatenation or a FLEURS sentence.

The local fixture is `/private/tmp/meeting-polish-gor-20241016-10min.wav`.
It is a 599.997-second, mono, 16 kHz PCM WAV extracted from the first ten
minutes of the official archived HLS stream with `ffmpeg`. Its SHA-256 is
`1045d5199ea673b56c63f77c02a59b9a6be7c2887f1922253c887e2f93f184b9`.
The downloaded official PDF is
`/private/tmp/meeting-polish-gor-20241016.pdf`, SHA-256
`a2720b1aff7d8cc0be596e5f23ba7e8a0b3675a706b2626cce14cf06d1b89a44`.
Both files are outside Git. Public access is established by the official
links; redistribution rights were not established, so neither file is
committed or included in release material.

To restage the audio on this Mac, use the `videoLink` returned by the
official API on 2026-10-02 and the same transform. A `HEAD` request to this
archive returned 404, whereas `GET` returned the playlist and `ffmpeg`
completed. If the archive link changes, retrieve its current `videoLink`
from the recording entry above. The following restaging steps are
repeatable; the existing file is kept when its checksum matches:

~~~bash
set -euo pipefail
video_url='https://sejm.c.blueonline.tv/stream/ENC23/518331A64B2ACCCDC1258BB20032D02B/playlist.m3u8?start=1729073040000&stop=1729074957000'
if ! shasum -a 256 /private/tmp/meeting-polish-gor-20241016-10min.wav 2>/dev/null | grep -q '^1045d5199ea673b56c63f77c02a59b9a6be7c2887f1922253c887e2f93f184b9 '; then
  ffmpeg -nostdin -hide_banner -loglevel error -y -i "$video_url" -t 600 -vn -ac 1 -ar 16000 -c:a pcm_s16le /private/tmp/meeting-polish-gor-20241016-10min.wav
fi
ffprobe -v error -show_entries format=duration,size -of json /private/tmp/meeting-polish-gor-20241016-10min.wav
shasum -a 256 /private/tmp/meeting-polish-gor-20241016-10min.wav
~~~

The official PDF is a human-readable, edited record of the sitting, not a
time-aligned word reference. It verifies the meeting and named speaker turns;
it cannot support a defensible whole-clip word error rate without alignment
and a verbatim audio reference. The [passage-level PDF/ASR
review](tests/polish_sejm_pdf_transcription_review_20261002.md) checks
recognizable turns and documents transcription errors. The [real-model test evidence](tests/polish_sejm_meeting_run_20261002.json)
records the prototype's output, repaired structural error, and remaining
Polish minutes content failure. The earlier
FLEURS experiment remains a separate, single-speaker language check in the
[benchmark](ami_asr_benchmark.md); it is not used as meeting evidence.
