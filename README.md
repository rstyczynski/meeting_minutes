# Meeting Summarizer — Product Vision

## Vision

Meeting Summarizer is a private, local-first companion for macOS and iOS that turns spoken and visual meetings into clear, attributable notes and follow-up actions—without sending audio, video, transcripts, or meeting metadata to the internet.

It should make a person leave any conversation with a trustworthy record of what was said, who said it, what was decided, and what needs to happen next.

## The problem

Important meeting context is routinely lost: people take incomplete notes, decisions are remembered differently, and action items disappear into chat threads. Existing transcription services often require uploading sensitive conversations to a cloud provider, which can be unacceptable for personal, business, legal, medical, or confidential discussions.

## The product promise

From a recorded or live meeting, the app produces an editable local meeting record:

1. A time-aligned transcription.
2. Recognized speakers/participants.
3. Speaker-attributed transcript segments.
4. Optional visual meeting evidence: video, shared-screen captures, slides, diagrams, and whiteboards.
5. A concise summary of discussion, decisions, open questions, and action items, informed by relevant visual material.
6. Optional real-time local alerts when the user’s name or a user-defined subject is mentioned.

All processing happens on the user’s device using local models. The product makes no network requests for recording, transcription, video analysis, speaker or participant recognition, diarization, visual understanding, summarization, or storage.

## Who it is for

- Professionals who handle confidential internal or client meetings.
- Individuals who want dependable notes without sharing recordings with a third party.
- Small teams and consultants who need accountable follow-ups from conversations.
- Users who value ownership of their data and the ability to work offline.

## Core experience

On macOS, a user can record an in-person meeting through the microphone and optional camera, or capture an online meeting’s permitted audio, video, and shared screen.

On iPhone or iPad, they can record an in-person conversation with optional video and capture a permitted screen recording. 

Screen capture on both platforms uses Apple’s OS-level recording services and their explicit permission flows; the app respects platform capability limits and never attempts to bypass them. After recording—or progressively during a live session—the app transcribes speech locally, separates speakers, links each utterance to a participant, and identifies meaningful visual moments.

The user reviews a single meeting page: audio/video playback, timestamped transcript, speaker labels, visual attachments, a generated summary, and action items. During an active recording, they may opt into discreet local alerts when their name or a chosen subject is mentioned; each alert opens the relevant point in the live transcript and recording. Every transcript segment links directly to the corresponding point in the recording, so a user can replay the source in one action. Relevant screen captures, diagrams, slides, or whiteboards are attached at their timestamps. The app may read text and interpret visual context locally to make the minutes more accurate, while preserving the visual source so the user can verify it. They can correct names, transcript text, or visual annotations; corrections should improve the current meeting immediately and, where the user explicitly allows it, help identify known voices or participants in future local meetings. The final record remains searchable and exportable from the device under the user’s control.

## Product principles

### Private by architecture

Audio, voice embeddings, transcripts, participant names, summaries, and indexes stay local. Offline operation is a product requirement, not a degraded mode. Any future sharing or export is explicit, user-initiated, and clearly scoped.

### Accurate, but transparent

The app must distinguish what it heard from what it inferred. Speaker labels can be marked as uncertain, and users can quickly relabel speakers or edit text. A correction must never be hidden behind a black-box workflow.

### Grounded in the meeting evidence

The outcome is a readable meeting record: purpose, summary, decisions, action items with owners when stated, and unresolved questions. The original audio/video, timestamped transcript, and relevant screen or diagram attachments remain available as the source of truth. Each transcript section has a direct recording timestamp link, and the summary should cite or link to the corresponding moment or attachment when visual material materially supports an interpretation.

### Native to Apple devices

The experience should feel at home on macOS and iOS: fast capture, clear consent cues, dependable background handling where platform rules allow, accessible editing, and secure device storage. Microphone, camera, and screen recording are requested through Apple’s OS-level services, with the operating system remaining the authority for permissions and capture availability. Records can be synchronized only through a user-controlled local/private mechanism if that is introduced later; cloud dependence is not assumed.

### Consent and control

Recording laws and organizational policies differ. The product should prominently remind users to obtain required consent, make recording status visible, and give straightforward controls to pause, delete, retain, or export a meeting.

## Scope of the first product

The first version focuses on making one meeting reliably useful:

- Record local microphone audio and optional camera video; use OS-level macOS/iOS screen-recording services for approved online-meeting and screen capture where technically and legally permitted.
- Import an existing audio or video recording.
- Run on-device speech-to-text.
- Perform speaker diarization and allow users to name and merge/split speaker labels; optionally associate visible participants with their speaker labels where confidence permits.
- Attribute transcript segments to participants and retain start/end timestamps that open the relevant point in the audio/video recording.
- Detect shared-screen and visual-change moments; attach captured frames, slides, diagrams, and whiteboards to the meeting timeline.
- Extract text and locally interpret relevant visual material to add context to the minutes, while allowing the user to keep material solely as an attachment.
- Allow the user to define names and subjects to monitor, then issue an on-device, configurable alert when they are mentioned in a live transcript.
- Generate a local summary, decisions, open questions, and action items.
- Search, edit, replay, export, and permanently delete meeting records locally.

The first version does not require calendar integrations, cloud accounts, server-side processing, automatic sharing, or cross-device synchronization.

## Success looks like

A user can finish a meeting, spend a few minutes reviewing the output, and confidently send themselves or their team a correct list of decisions and next steps. When a decision depends on a screen, diagram, or slide, they can see the relevant visual evidence in context. They understand where their data lives, can work with airplane mode enabled, and can recover the evidence behind every generated summary item through the original recording, attributed transcript, and visual attachments.

## Longer-term direction

Over time, Meeting Summarizer can become a personal, private memory for conversations: locally searchable meeting history, user-approved recognition of recurring participants, visual search across shared materials, configurable summary styles, and selective exports to the user’s chosen tools. These capabilities must preserve the foundational promise: the user—not a remote service—owns the meeting data and controls where it goes.
