#!/usr/bin/env python3
"""Convert AMI manual word XML into a local, timed scoring reference.

The output contains meeting content. Keep it outside Git.
"""

import argparse
import json
import math
import xml.etree.ElementTree as ET
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--annotations", type=Path, required=True)
    parser.add_argument("--meeting", default="ES2002a")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    words = []
    for speaker in "ABCD":
        path = args.annotations / "words" / f"{args.meeting}.{speaker}.words.xml"
        if not path.is_file():
            parser.error(f"Missing manual word reference: {path}")
        root = ET.parse(path).getroot()
        speaker_count = 0
        for element in root.iter("w"):
            if element.attrib.get("punc") == "true":
                continue
            text = "".join(element.itertext()).strip()
            if not text:
                continue
            start = float(element.attrib["starttime"])
            end = float(element.attrib["endtime"])
            if not all(map(math.isfinite, (start, end))) or start < 0 or end < start:
                parser.error(f"Invalid word time in {path}: {start}..{end}")
            words.append({
                "speaker": speaker,
                "start_seconds": start,
                "end_seconds": end,
                "text": text,
            })
            speaker_count += 1
        if not speaker_count:
            parser.error(f"No timed words for speaker {speaker}: {path}")
        print(f"{speaker}: {speaker_count} timed words")

    words.sort(key=lambda word: (word["start_seconds"], word["end_seconds"], word["speaker"]))
    payload = {
        "meeting_id": args.meeting,
        "annotation_release": "AMI public manual 1.6.2",
        "words": words,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"Wrote {len(words)} timed words to {args.output}")


if __name__ == "__main__":
    main()
