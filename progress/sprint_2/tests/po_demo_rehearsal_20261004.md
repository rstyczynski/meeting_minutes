# Sprint 2 — single-command Product Owner demo rehearsal, 4 October 2026

The developer ran `bash progress/sprint_2/demo/run.sh --check` on the
Sprint 2 Mac. All exact audio, model, executable, shader, saved-trial,
`swift` and `jq` prerequisites passed. `bash
progress/sprint_2/demo/run.sh --rehearsal` then ran the real local models
from the repository root and completed with process status 0. This was a
CLI-only rehearsal, not the live Product Owner review.

The new store is
`/private/tmp/meeting-sprint2-po-demo.zJb0bY`. AMI English record
`9EFDB566-3E63-48D4-AE0D-6BC3702F3DF6` saved 2576 timed Parakeet v2
segments, S1–S3, and 16 weak-audio warnings. Sejm Polish record
`2CD29FB6-A075-4C9B-86AB-A1124F5FF3E9` saved 802 timed Parakeet v3
segments, S1–S3, and zero weak-audio warnings. `inspect-cleanup` saved
17 join proposals and 32 reading utterances to `sejm-cleanup.json`. The
count differs from the earlier fixed Sejm run's 16 proposals and 801
segments; the live script therefore treats slide 8 as a recorded example
and prints fresh counts and IDs.

The new 120-second AMI record
`A6338D3C-B131-482E-AE2B-1EB10C950C64` retained 210 timed segments.
Its current multi-stage 30B minutes attempt exited 2: `summary_t4 failed
after two repairs: No substantial exact excerpt remains in cited
utterances`. The full Sejm minutes attempt also exited 2: `topics failed
after two repairs: The data couldn’t be read because it isn’t in the
correct format.` Each record retained zero review items and its full
transcript. This observed fresh failure is a presentation finding, not a
claim of successful minutes generation. The same script clearly prints
the prior successful controlled 30B records, with 2/5 AMI and 2/4 Sejm
summaries supported by their own sources, as **recorded evidence**.

The first rehearsal attempt inside the command sandbox stopped before
transcription because SwiftPM reported `sandbox_apply: Operation not
permitted`. A rerun with the tool's approved escalated execution reached
all CLI stages. This is an execution-environment permission issue, not a
recorded product ASR failure. SwiftPM also printed repetitive PIF build
warnings; the demo script now sends those diagnostics to the result
store's `cli-stderr.log` and displays adapter errors when a CLI step fails.

The rehearsal did not open the Meeting Review window for a human to
listen, did not make an audio-reviewed word correction, and did not
verify or assign a real speaker name. Those are explicit interactive
steps in the live script. Slide 9's positive correction and restore
example remains a controlled test, not an audio-verified correction of
this meeting. The live Product Owner questions and decision have not
occurred and must be added to the handover record after the session.

After the script was finalized, a second complete `--rehearsal` run
returned 0 with build warnings kept in the store rather than filling the
presentation Terminal. Its store is
`/private/tmp/meeting-sprint2-po-demo.ONxSmk`; its AMI, Sejm, and AMI
120-second UUIDs are `4DEF5295-8A18-47EF-8A43-20393E0D2318`,
`4A646447-449F-4659-8F30-F9C51CAFEC7E`, and
`C918DB13-6E1E-413B-9D34-444F7F148ADD`. It reproduced the 2576/802
transcript counts, 16/0 warning counts, 17 join proposals, 32 reading
utterances, and two fresh minutes rejections. The AMI rejection reported
`Reconciled 0 topic proposal citations into assignments`; the Sejm
rejection remained a topics response-format failure after two repairs.
The exact error may change because the model is not deterministic.

The final slide-aligned script was rehearsed once more and returned 0.
Its store is `/private/tmp/meeting-sprint2-po-demo.x3Qd2I`; the fresh
AMI, Sejm and AMI 120-second records are
`90E417AF-E3F2-4086-A0F5-0019FBAEFC77`,
`6B8931A1-45FA-45FA-8D88-180FCB527D76`, and
`1754513D-F2C4-4C13-8ACF-1ED0E4C8C90C`. The script displayed the
Sejm opening at 181–220 seconds, actual raw segments at 565–569 seconds,
their proposed `utt_30` reading view, the saved AMI meaning-confusion
source utterances, and the Sejm decision's source words. It again saved
2576/802 timed segments, 16/0 warnings, 17 cleanup proposals and 32
reading utterances. Both fresh minutes attempts exited 2 and retained
the transcripts with zero review items. The script's own status 0 means
the walkthrough reached its conclusion; it does **not** mean minutes
quality passed. This final rehearsal still did not include human audio
playback or a real correction.

The corrected, fully slide-aligned demo then completed a fourth real-model
`--rehearsal` with status 0. Store
`/private/tmp/meeting-sprint2-po-demo.Zz35wD` contains AMI
`F4841F18-9D25-4D91-BD09-D9A339D03B76`, Sejm
`DD5E817B-C77A-46B6-A1E0-7648409B6586`, and AMI 120-second
`0C92965D-D4DE-4A6C-81B8-147CFFB7922E`. The new slide-9 guard used a
copy of the real Sejm record: without `--audio-reviewed yes`, the CLI
returned 2 and its SHA-256 was identical before and after. The script
also printed the four historical pre-gate Sejm review items on slide 11,
including the supported decision, unsupported action, invented question,
and uncited summary. All fresh transcription, warning and cleanup counts
matched the preceding run; both fresh 30B minutes attempts were rejected
and preserved their transcripts. No human playback, real correction,
speaker name, or Product Owner decision is claimed.
