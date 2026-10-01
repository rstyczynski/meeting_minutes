#!/usr/bin/env bash
set -euo pipefail

# TODO: implement XCTest assertions in the approved Package test target.
test_UT1_record_ranges() { swift test --filter MeetingCoreTests/testRecordRanges; }
test_UT2_atomic_store() { swift test --filter MeetingCoreTests/testAtomicStore; }
test_UT3_import_rejection() { swift test --filter MeetingCoreTests/testImportRejection; }
test_UT4_corrections() { swift test --filter MeetingCoreTests/testCorrections; }
test_UT5_minutes_validation() { swift test --filter MeetingCoreTests/testMinutesValidation; }
test_UT6_backend_configuration() { swift test --filter MeetingCoreTests/testBackendConfiguration; }

if [[ -n "${1:-}" ]]; then
  "$1"
else
  test_UT1_record_ranges
  test_UT2_atomic_store
  test_UT3_import_rejection
  test_UT4_corrections
  test_UT5_minutes_validation
  test_UT6_backend_configuration
fi
