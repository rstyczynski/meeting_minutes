# Meeting Summarizer — Roadmap

## Lifecycle roadmap

1. Inception
   1. Analyze and agree the vision.
   2. Define the internal use cases and meeting scenarios.
   3. Turn the vision into functional and non-functional requirements.
   4. Establish and prioritize the Product Backlog as Product Owner-level product increments.
   5. Define the MVP scope and acceptance criteria.
   6. Identify constraints and risks.
   7. Define the initial candidate architecture and its key technology assumptions.
   8. Review the vision, requirements, backlog, and candidate architecture for internal consistency.
   9. Validate the vision against comparable market products and identify meaningful differentiation.
2. Elaboration
   1. Define the experiments and acceptance measures.
   2. Identify, select, and benchmark local capture, transcription, diarization, summary, and visual-processing libraries.
   3. Refine and baseline the macOS-first system architecture, security boundary, and meeting-record data model.
   4. Build an architectural prototype for local capture/import, transcription, and timestamped source playback.
   5. Resolve the highest risks and update the architecture and MVP scope.
3. Construction
   1. Implement local capture/import, storage, and the timestamped transcript.
   2. Implement speaker diarization, participant assignment, and correction tools.
   3. Implement screen/visual attachments, structured minutes, and evidence traceability.
   4. Implement local live alerts for monitored names and subjects.
   5. Implement search, export, deletion, and offline/privacy controls.
   6. Test each increment against representative internal meetings.
4. Transition
   1. Harden reliability, performance, privacy, and the data lifecycle.
   2. Prepare consent, permission, and operating guidance for the team.
   3. Release to the internal team and provide a feedback path.
   4. Fix issues that prevent the minutes from being trusted as a meeting record.

## Brief notes

### 1. Inception

The outputs are `MARKET.md`, `REQUIREMENTS.md`, `BACKLOG.md`, `MVP.md`, `RISK_REGISTER.md`, and an initial `ARCHITECTURE.md`. `MARKET.md` validates the vision against comparable meeting products and identifies opportunities for meaningful differentiation. Requirements must cover recording/import, transcription, speakers, visual evidence, structured minutes, traceability, alerts, local storage, export, and deletion. They must also define offline operation, privacy, permissions, performance, licensing, and recording-consent constraints.

`BACKLOG.md` contains Product Owner-level product increments: a concise statement of what is needed, why it matters, and how acceptance will be recognized. Prefer a thin, observable functional outcome over a technical task. A technical-enablement or risk-reduction item is valid when it is necessary to unlock a product outcome, but it must state the value and acceptance signal rather than prescribe design or implementation.

### 2. Elaboration

The outputs are `ARCHITECTURE_VALIDATION.md`, a validated prototype, and a baselined `ARCHITECTURE.md`. `ARCHITECTURE_VALIDATION.md` records local-library candidates, benchmark results, and selected technologies. The architecture must cover capture, local media storage, processing, live alerts, the meeting record, local search, export/deletion, and the native macOS UI. Every transcript or summary statement must link to its source timestamp or attachment. Run experiments using consented internal recordings.

### 3. Construction

Deliver the macOS MVP as working vertical increments. Keep it local-only and do not add calendar bots, third-party integrations, automatic sharing, facial identification, or cross-device sync. Test source traceability, correction flow, alert quality, offline behavior, and recording reliability continuously.

### 4. Transition

Release first to a small consented internal group. Provide concise guidance for recording consent, OS permissions, correction, export, and deletion. Stabilize capture, traceability, speaker attribution, and summary output before expanding use.

## Subsequent iterations

After Transition, review internal usage, limitations, and improvement requests. Decide the first iOS/iPadOS role—recording, import, review, alerts, or a combination—and begin a new iteration with Inception. The vision stays in [vision.md](1.Inception/vision.md).
