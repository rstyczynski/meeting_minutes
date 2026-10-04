#!/usr/bin/env bash
set -euo pipefail

# The named cases were specified in the accepted design and use Swift Testing.
test_UT1_record_ranges() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testRecordRanges'; }
test_UT2_atomic_store() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testAtomicStore'; }
test_UT3_import_rejection() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testImportRejection'; }
test_UT4_corrections() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testCorrections'; }
test_UT5_minutes_validation() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testMinutesValidation'; }
test_UT6_backend_configuration() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testBackendConfiguration'; }
test_UT7_transcript_only() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testTranscriptOnly'; }
test_UT8_chair_corrections() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testChairCorrections'; }
test_UT9_optional_minutes() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testOptionalMinutes'; }
test_UT10_language_compatibility() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testLanguageCompatibility'; }
test_UT11_evidence_first_minutes() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testEvidenceFirstMinutes'; }
test_UT12_minutes_input_bound() { swift test --filter 'MeetingCoreTests.MeetingCoreTests/testMinutesInputBound'; }
test_UT13_adapter_validation() { swift test --package-path experiments/MinutesAdapter --filter ResponseValidationTests; }
test_UT14_transcript_cleaning() { swift test --filter 'MultiStageTests/testTranscriptCleaning'; }
test_UT15_topic_coverage() { swift test --filter 'MultiStageTests/testTopicCoverage'; }
test_UT16_stage_validation() { swift test --package-path experiments/MinutesAdapter --filter 'PipelineValidationTests/testStageValidation'; }
test_UT17_isolated_token_review() { swift test --filter 'MultiStageTests/testIsolatedTokenReview'; }
test_UT18_operator_text_correction() { swift test --filter 'MultiStageTests/testAudioReviewedTextCorrectionIsReversible'; }

test_UT19_selected_text() { swift test --filter 'MultiStageTests/testSelectedTextCorrection'; }
test_UT20_playback_context() { swift test --filter 'MultiStageTests/testPlaybackContext'; }

test_UT21_long_silence() { swift test --filter 'MultiStageTests/testLongSilenceBoundary'; }

test_UT22_transcript_audio_sync() { swift test --filter 'MultiStageTests/testTranscriptAudioSynchronization'; }

if [[ -n "${1:-}" ]]; then
  "$1"
else
  test_UT1_record_ranges
  test_UT2_atomic_store
  test_UT3_import_rejection
  test_UT4_corrections
  test_UT5_minutes_validation
  test_UT6_backend_configuration
  test_UT7_transcript_only
  test_UT8_chair_corrections
  test_UT9_optional_minutes
  test_UT10_language_compatibility
  test_UT11_evidence_first_minutes
  test_UT12_minutes_input_bound
  test_UT13_adapter_validation
  test_UT14_transcript_cleaning
  test_UT15_topic_coverage
  test_UT16_stage_validation
  test_UT17_isolated_token_review
  test_UT18_operator_text_correction
  test_UT19_selected_text
  test_UT20_playback_context
  test_UT21_long_silence
  test_UT22_transcript_audio_sync
fi
