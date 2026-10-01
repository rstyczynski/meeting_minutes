#!/usr/bin/env python3
"""Build an invented two-speaker meeting fixture with macOS say and ffmpeg."""

from array import array
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import wave


ROOT = Path(__file__).resolve().parent
RATE = 16000
GAP_SECONDS = 0.45
UTTERANCES = [
    ("speaker_1", "Daniel", "Let's review the release plan for Friday."),
    ("speaker_2", "Samantha", "The audio import is ready for a small test."),
    ("speaker_1", "Daniel", "We decide to test both transcription engines on the same recording."),
    ("speaker_2", "Samantha", "I will write the reference transcript by Thursday."),
    ("speaker_1", "Daniel", "Who will check the speaker labels? That is still open."),
]


def synthesize(index: int, voice: str, text: str, directory: Path) -> array:
    aiff = directory / f"turn_{index}.aiff"
    wav = directory / f"turn_{index}.wav"
    subprocess.run(["say", "-v", voice, "-o", str(aiff), text], check=True)
    subprocess.run(
        [
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-i", str(aiff), "-ac", "1", "-ar", str(RATE),
            "-c:a", "pcm_s16le", str(wav),
        ],
        check=True,
    )
    with wave.open(str(wav), "rb") as source:
        if source.getnchannels() != 1 or source.getframerate() != RATE:
            raise ValueError("Unexpected synthesized audio format")
        samples = array("h")
        samples.frombytes(source.readframes(source.getnframes()))
        if sys.byteorder != "little":
            samples.byteswap()
        if len(samples) < RATE // 4 or not any(samples):
            raise RuntimeError(
                "Speech synthesis produced empty audio; run with macOS voice access"
            )
        return samples


def main() -> None:
    output = array("h")
    turns = []
    with tempfile.TemporaryDirectory(prefix="synthetic-meeting-") as temp:
        for index, (speaker, voice, text) in enumerate(UTTERANCES, start=1):
            samples = synthesize(index, voice, text, Path(temp))
            start_sample = len(output)
            output.extend(samples)
            end_sample = len(output)
            output.extend([0] * round(GAP_SECONDS * RATE))
            turns.append(
                {
                    "id": f"turn_{index}",
                    "speaker": speaker,
                    "text": text,
                    "start_seconds": round(start_sample / RATE, 3),
                    "end_seconds": round(end_sample / RATE, 3),
                }
            )

    audio = ROOT / "synthetic_meeting.wav"
    with wave.open(str(audio), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        if sys.byteorder != "little":
            output.byteswap()
        target.writeframes(output.tobytes())

    reference = {
        "fixture_id": "synthetic_meeting_v1",
        "provenance": "Invented dialogue synthesized with macOS say; no real meeting content",
        "audio_file": audio.name,
        "sample_rate_hz": RATE,
        "channels": 1,
        "speakers": {"speaker_1": "Daniel voice", "speaker_2": "Samantha voice"},
        "turns": turns,
        "minutes": {
            "decision": {"text": "Test both transcription engines on the same recording", "source_turns": ["turn_3"]},
            "action": {"text": "Write the reference transcript by Thursday", "owner": "speaker_2", "source_turns": ["turn_4"]},
            "open_question": {"text": "Who will check the speaker labels?", "source_turns": ["turn_5"]},
        },
    }
    (ROOT / "synthetic_meeting_reference.json").write_text(
        json.dumps(reference, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Generated {audio} and its reference JSON")


if __name__ == "__main__":
    main()
