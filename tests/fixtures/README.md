# Synthetic meeting fixture

`synthetic_meeting.wav` is invented dialogue synthesized with the macOS
Daniel and Samantha voices. It contains no real meeting content.
`synthetic_meeting_reference.json` records the expected words, speaker turns,
time ranges, decision, action, and open question. The WAV is mono 16-bit PCM
at 16 kHz, suitable as identical input for the FluidAudio and whisper.cpp
comparison.

Regenerate both files on macOS with `python3
tests/fixtures/generate_synthetic_meeting.py`. This requires `say`, `ffmpeg`,
and access to the installed voices. The script rejects empty speech output.
Different macOS voice releases can produce different timings, so keep this
checked-in WAV and reference JSON paired for each benchmark. Record their
checksums with the experiment results.

This fixture checks the benchmark pipeline and explicit content references.
It does not represent natural meeting speech, acoustic noise, or overlapping
speakers. Representative accuracy requires an approved local sample outside
the repository, as described in the Sprint 2 design and
`docs/test-profile.md`.
