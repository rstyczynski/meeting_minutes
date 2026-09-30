# Sprint 1 — More information needed

## Initial release boundary

Status: Accepted

Problem to clarify: The accepted vision requires imported locally available
recordings and live screen capture, but it does not say which additional
capabilities belong in the first release. The retained draft MVP proposes
direct recording, visual attachments, local alerts, search, export, and
permanent deletion; it is not accepted scope.

Answer: The MVP is for a single local operator. It accepts a user-supplied
local recording through a CLI argument, creates a local transcript with
speaker labels that the meeting chair can correct and associate with
participants, and produces local minutes and action items. Live screen
capture, direct recording, visual attachments, alerts, search, export, and
permanent deletion are deferred.

## Initial user and consent model

Status: Accepted

Problem to clarify: Should the first release be designed for a single local
operator, and should it include only operator-facing consent guidance rather
than participant management or organization policy features? This affects
stakeholders, privacy requirements, and the release acceptance criteria.

Answer: Yes. The initial release is designed for a single local operator.
The meeting chair and participants are meeting-record roles, not separate
accounts or organization-management features. Consent guidance is operator
facing; participant management and organization policy features are deferred.

## Toolchain direction

Status: Accepted

Problem to clarify: PBI-009 must complete `docs/test-profile.md` with exact
commands before Sprint 2. May the candidate architecture propose a Swift/
SwiftUI macOS app with a Swift Package shared core and XCTest, subject to your
design approval, or do you have a different preferred stack?

Answer: Accepted. The candidate architecture may propose a Swift/SwiftUI
macOS app with a shared Swift Package core and XCTest, subject to managed
design approval.
