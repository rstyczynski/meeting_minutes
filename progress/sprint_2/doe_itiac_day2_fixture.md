# English multi-person public meeting validation source

The [U.S. Department of Energy Industrial Technology Innovation Advisory
Committee Day 2 page](https://www.energy.gov/cmei/ito/industrial-technology-innovation-advisory-committee-first-meeting-day-2-text-version)
provides an official, speaker-labeled transcript and links the [department's
meeting recording](https://www.youtube.com/watch?v=5b1h1WHExuc). The meeting
was held on 22 March 2024. The recording is published by the U.S. Department
of Energy and is about 2 hours 40 minutes long. Its opening includes
Zachary Pritchard, a recorded meeting notice, Sharon Nolen, and later
committee members speaking to one another. This is a real public meeting,
not a single-person speech or a constructed audio sequence.

For the Sprint 2 long-input test, the first 30 minutes of the official
recording were decoded to `/private/tmp/meeting-doe-itiac-day2-30min.wav`.
It is mono, 16 kHz PCM, exactly 1,800 seconds, and 57,600,078 bytes. Its
SHA-256 is
`a0351f3cbae39118864e1a90b245590fbf5543956211bc305c5afa5c662f0d9b`.
The downloaded source audio is
`/private/tmp/meeting-doe-itiac-day2.webm`, SHA-256
`44153b4bd83474f4fb563e0ef749f839ad5313986f1effc25b750bd1d55bfd8a`.
Both are outside Git. The public official links establish access, but
redistribution rights for the hosted copy have not been assessed, so no
recording is included in the repository.

The following commands reproduce the local audio on the Sprint 2 Mac.
`yt-dlp` 2026.8.19 was installed in the temporary environment shown; its
source format 251 is Opus in WebM. The commands were run on 2026-10-02;
the final probes and hashes were checked against the values above.

~~~bash
if ! test -f /private/tmp/meeting-doe-itiac-day2.webm; then
  /private/tmp/meeting-hf-venv/bin/yt-dlp --no-playlist --js-runtimes node:/opt/homebrew/bin/node -f 251 -o '/private/tmp/meeting-doe-itiac-day2.%(ext)s' 'https://www.youtube.com/watch?v=5b1h1WHExuc'
fi
if ! test -f /private/tmp/meeting-doe-itiac-day2-30min.wav; then
  ffmpeg -nostdin -hide_banner -loglevel error -i /private/tmp/meeting-doe-itiac-day2.webm -t 1800 -vn -ac 1 -ar 16000 -c:a pcm_s16le /private/tmp/meeting-doe-itiac-day2-30min.wav
fi
ffprobe -v error -show_entries format=duration,size -of json /private/tmp/meeting-doe-itiac-day2-30min.wav
shasum -a 256 /private/tmp/meeting-doe-itiac-day2-30min.wav
~~~

The real CLI transcribed the excerpt with Parakeet v2 as record
`36237678-66EB-456D-897A-4687BF33F390` in
`/private/tmp/meeting-doe-itiac-sprint2`. It saved 4,216 timed segments
covering the full 30 minutes. Its first words match the official opening.
Fluid diarization assigned eight anonymous IDs and zero weak-audio
warnings. S1 begins with Zachary Pritchard's greeting at about 3 seconds;
S3 begins where the official transcript passes to Sharon Nolen at about
128 seconds; and S5 begins near Sue's question at about 852 seconds. These
turn-level comparisons confirm that the excerpt has multiple people and
the labeling path ran. They do not establish whole-cluster identity or
speaker-attribution accuracy.

The official HTML transcript is speaker-labeled but not time aligned to
the extracted WAV, so no whole-excerpt word error rate is claimed. The
[run capture](tests/doe_itiac_day2_run_20261002.json) records the model
outputs and minutes attempts. This English fixture complements the
[Polish Sejm meeting](polish_sejm_meeting_fixture.md) and the AMI weak-headset
meeting without changing the paired ASR benchmark basis.
