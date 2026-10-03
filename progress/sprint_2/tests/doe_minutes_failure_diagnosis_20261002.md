# Minutes failure diagnosis — 2026-10-02

This is test evidence for the existing public DOE meeting input and a launch
reproduction on the short AMI record. It does not claim that generated
minutes are correct.

## DOE 30-minute adapter response

The [DOE run capture](doe_itiac_day2_run_20261002.json) identifies the
30-minute, 4,216-segment saved record. The existing `MeetingCore` grouping
rule produced 324 model-facing source chunks from that record. A direct
adapter diagnostic used those chunks with the pinned Qwen3-4B model and
saved its [raw output wrapper](doe_minutes_raw_adapter_response_20261002.json).
The adapter command was:

~~~bash
swift run --package-path experiments/MinutesAdapter meeting-mlx-minutes /private/tmp/meeting-minutes-models/qwen3-4b-instruct-2507-4bit /private/tmp/meeting-doe-raw-adapter-input.json /private/tmp/meeting-doe-raw-adapter-output.json
~~~

The response has 3,715 characters and ends in the middle of a quoted
`source_ids` value. A JSON parse reports an unterminated string at position
3,707. The model generated two decisions, two actions, and began a second
question despite the prompt's limits, with more than the requested three
citations on several items. The adapter requests `maxTokens: 1024`. This
identifies a truncated response as the immediate cause of the 4B JSON
failure. It does not prove that the long transcript alone caused the model
to exceed the output budget; the model's failure to obey output-size limits
also contributed. Some generated claims need separate source review. The
7B attempt's raw response was not retained and cannot receive this same
root-cause conclusion.

## Direct CLI launch check

The [fresh short AMI record](4395B92A-60B8-4B8C-9A20-3AE37642FE92.json)
was copied into a scratch store before this check. The direct
`.build/debug/meeting-summarizer summarize` invocation exited 2 in about
0.3 seconds with an adapter `NSRangeException` in an MLX C++ symbol. The
same record, settings, model and binary were then invoked through
`swift run meeting-summarizer summarize`, which exited 0. A further
`swift run --skip-build meeting-summarizer summarize` call also exited 0.
The latter rules out a rebuild as the necessary difference. The direct
binary was retried after the successful `swift run` call and still exited 2.

The launch environment difference is not isolated. In particular, no
specific entitlement, Metal device enumeration, or filesystem sandbox rule
is established as the root cause. The supported Sprint 2 demonstration
continues to use `swift run`, which the Product Owner allowed for
Elaboration. The direct binary is not a passed delivery path.
