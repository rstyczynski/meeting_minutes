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
fi
