# Sprint 2 — More information needed

## PBI-011 — Meaning of recognize

Status: None

Problem to clarify: The Product Owner named three CLI stages:
transcribe, recognize, summarize. Does recognize mean chair-controlled
assignment of names to diarized speaker IDs, automatic identity recognition
from enrolled voice samples, or both? Automatic identity recognition would
need separate data, model, consent, and validation scope; neutral diarization
plus manual name assignment is already within the prototype's correction
workflow.

Answer: Both chair-controlled name assignment or correction and optional
automatic name suggestions from local evidence, which may include media
content and locally supplied voice references. Automatic discovery is a
nice-to-have functional requirement beyond the initial MVP. Diarization
labels alone are not identities. The Sprint 2 architecture experiment does
not select the automatic discovery method.
