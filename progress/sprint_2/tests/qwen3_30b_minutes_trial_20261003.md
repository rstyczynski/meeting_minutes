# Qwen3 30B local minutes trial — 3 October 2026

## Question and controlled input

Can a locally staged Qwen3-30B-A3B-Instruct-2507 4-bit model produce
usable, cited draft minutes from the same English AMI and Polish Sejm
transcripts that exposed the 4B and 7B limitations? This trial used the
same `minutes-v3-evidence` prompt, 1,024-token response limit, source-chunk
mapping, validators, and at most two repair prompts. Only the model
directory changed. The 30B artifact is pinned and hash checked in the
[download record](qwen3_30b_download_20261003.md).

The clean evaluation store copied the saved AMI 120-second record
`4395B92A-60B8-4B8C-9A20-3AE37642FE92` and Sejm ten-minute record
`5DC83D71-D1B0-4568-A66D-70F3B9A71D46`, cleared old review items, and
left their transcript segments intact. A field-by-field comparison to the
original saved records confirmed identical segment arrays: 217 AMI and
801 Sejm segments. Canonical sorted-segment SHA-256 values are
`47af8a90c84326925a702b755b3dd3af9fc5968e267f916baf7b6317ed9cf01f`
and `4c0f5f354a879dce8cbde7bbd6abe441c8eee6aa4ba0ab0fad8e3c12dabbc029`.
This checks the **transcript** input, not identical audio inference. The
Sejm transcript comes from Parakeet v3; its passage-level comparison with
the official PDF is in the [Polish transcription review](polish_sejm_pdf_transcription_review_20261002.md).

The CLI calls were `meeting-summarizer summarize <record-id> --summarizer
mlx --settings /private/tmp/meeting-30b-eval-20261003/settings.json
--store /private/tmp/meeting-30b-eval-20261003`, timed with `/usr/bin/time
-l`. The settings pointed `mlxModelDirectory` to the pinned local 30B
weights and `mlxExecutable` to the release MLX Swift adapter. Raw model
responses were captured per attempt only because
`MEETING_MINUTES_DIAGNOSTICS_DIR` was set for this experiment. The product
does not save these diagnostic files in a normal run.

## English AMI result

The CLI exited 0 after **11.97 seconds**. `/usr/bin/time -l` reported
**9,771,171,840 bytes** maximum resident set size for the timed command;
this is a host observation, not a separate GPU allocation measurement.
The first response quoted the product brief but cited only `source_27`.
That quote spans `source_27` and `source_28`; the validator requested a
repair and the second response cited both. The final answer passed the
technical gate. The saved [AMI record](qwen3_30b_ami_20261003/record.json)
contains one summary and no decisions, actions, or open questions. The
summary is an exact excerpt about designing a remote control, at
108.72–120 seconds. It is source supported, but it repeats the brief and
does not show that the model can draft useful meeting minutes. The
[initial](qwen3_30b_ami_20261003/minutes_attempt_0.json) and
[repaired](qwen3_30b_ami_20261003/minutes_attempt_1.json) model responses
and [run log](qwen3_30b_ami_20261003/run.log) are retained.

## Polish Sejm result

The CLI exited 2 after **26.32 seconds**. `/usr/bin/time -l` reported
**17,325,785,088 bytes** maximum resident set size. All three raw responses
have the same malformed JSON: the `decisions` array is missing its closing
bracket before `actions`. The first and second repair prompts did not
change that output. The technical gate rejected it; the saved [Sejm
record](qwen3_30b_sejm_20261003/record.json) retains all 801 segments
and zero review items. The [initial](qwen3_30b_sejm_20261003/minutes_attempt_0.json),
[first repair](qwen3_30b_sejm_20261003/minutes_attempt_1.json), and
[final rejected response](qwen3_30b_sejm_20261003/minutes_attempt_2.json)
plus the [run log](qwen3_30b_sejm_20261003/run.log) make the failure
reproducible.

The rejected text attempts a positive-opinion decision, a meaningful
event in the official sitting. It is still unsafe to accept: the model
spelled `uznaję` with a Cyrillic character, cited only `source_73`
(540.72–545.84 seconds), and quoted words that continue in `source_74`
(545.84–553.20 seconds). Its summary cites an incomplete opening
time-limit sentence from `source_1`. Thus merely closing the JSON array
would not make the citation and text pass source review.

## Technical limits and decision

An initial sandboxed AMI attempt crashed inside MLX before model inference.
The clean Swift build had also removed `mlx.metallib`; copying the newly
compiled `default.metallib` beside the adapter restored its required
packaging. The successful AMI and failed Sejm inference runs were then
executed outside the filesystem sandbox with GPU access. The first crash
is an environment/runtime observation, not a minutes-quality result.

The 30B candidate improves one narrow outcome: AMI returned a technically
valid, exact cited excerpt after repair. It does **not** demonstrate useful
minutes across these two real meetings. Polish response structure and
quotation/citation fidelity failed, and the English output contained only
a brief quotation. The model is not promoted to the product default, and
the Sprint 2 minutes delivery blocker remains. These are two examples,
not statistical accuracy estimates or a model-family ranking.
