# Meeting Summarizer — Architecture Validation

## Goal

Validate the candidate architecture and retire its highest technical risks before full construction. Run time-boxed experiments using a consented test corpus that includes an in-person discussion, an online meeting with shared slides, overlapping speech, and the target languages or accents.

## Candidate local libraries and frameworks

**Capture:** Apple ScreenCaptureKit and AVFoundation for permitted screen, audio, and video capture.

**Speech-to-text:** whisper.cpp and a Core ML implementation.

**Speaker diarization:** pyannote.audio as an offline benchmark; evaluate an Apple-compatible ONNX or Core ML pipeline for shipping.

**Local summarization:** MLX Swift and llama.cpp with a commercially usable local instruct model.

**Visual processing:** Apple Vision and Core ML for OCR and frame selection; evaluate a local vision-language model only if needed.

## Areas to validate

**Capture.** Use Apple ScreenCaptureKit and AVFoundation for macOS. Validate selection and recording of permitted screen content, system audio, microphone, and optional camera through the native consent flow. On iOS and iPadOS, validate microphone/camera capture and permitted screen capture through Apple system services.

**Speech-to-text.** Benchmark whisper.cpp and a Core ML implementation where it improves performance. Measure transcript accuracy, timestamp quality, processing speed, memory use, battery effect, and model footprint.

**Speaker turns and identity.** Use pyannote.audio as an offline benchmark and investigate an ONNX- or Core ML-capable pipeline suitable for shipping. Measure diarization error. Support temporary speaker labels and fast user rename/merge controls before persistent voice identity.

**Local summarization.** Evaluate MLX Swift and llama.cpp with small instruct models that permit the intended use. Generate structured minutes without network access and attach citations to source timestamps.

**Real-time alerts.** Test incremental local transcription and lightweight name/subject matching while recording. The user must be able to configure monitored names and subjects, receive a discreet on-device alert, and open the triggering transcript moment. Measure alert latency, missed mentions, and false alerts separately from final transcript accuracy.

**Screens, slides, and diagrams.** Use Apple Vision/Core ML for OCR and frame selection; consider a local vision-language model later. Detect meaningful visual changes, save representative frames, extract readable text, and link attachments to the timeline.

**Local storage and search.** Evaluate SwiftData or Core Data with encrypted-at-rest storage and local full-text search. A meeting record must survive restart, remain local, be searchable, and be securely deletable.

## Acceptance criteria

For a 60-minute recording on representative Apple Silicon hardware:

- Capture finishes without dropped or corrupt media in normal use.
- Every transcript segment opens the source audio/video at its timestamp.
- A user can correct a speaker label in seconds.
- Minutes identify decisions, owners only when explicitly stated, actions, and open questions; every item links to supporting evidence.
- No runtime network connection is required after models are installed.
- A configured name or subject can generate a local alert during recording and open the supporting transcript moment.
- Performance, storage, model licensing, and App Store distribution constraints are understood before selecting the shipping stack.

## Quality and trust requirements

- Create a consented evaluation set that reflects the meetings the tool will actually support.
- Measure word error rate, diarization error rate, action-item precision/recall, summary evidence coverage, capture reliability, and processing time.
- Make uncertainty visible: unknown speaker, uncertain visual interpretation, or unsupported summary claim.
- Test the correction loop; corrections must immediately improve the current meeting record.
- Define the complete data lifecycle: recording status, permissions, model installation, encryption and storage, retention, export, and irreversible deletion.
- Obtain appropriate legal advice before any commercial distribution concerning recording consent and biometric-identifier processing.

## References

- [Apple ScreenCaptureKit documentation](https://developer.apple.com/documentation/screencapturekit)
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
- [pyannote.audio](https://github.com/pyannote/pyannote-audio)
- [MLX Swift](https://github.com/ml-explore/mlx-swift) and [llama.cpp](https://github.com/ggml-org/llama.cpp)
