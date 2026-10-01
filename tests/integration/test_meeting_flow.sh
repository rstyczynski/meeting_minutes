#!/usr/bin/env bash
set -euo pipefail

# TODO: implement synthetic fixture scenarios in the approved XCTest target.
test_IT1_cli_record() { swift test --filter MeetingIntegrationTests/testCLIRecordOpen; }
test_IT2_source_links() { swift test --filter MeetingIntegrationTests/testSourceLinks; }
test_IT3_correction_review() { swift test --filter MeetingIntegrationTests/testCorrectionAndReview; }
test_IT4_chunk_merge() { swift test --filter MeetingIntegrationTests/testChunkMerge; }
test_IT5_backend_selection() { swift test --filter MeetingIntegrationTests/testBackendSelection; }
test_IT6_fixture_generation() { swift test --filter MeetingIntegrationTests/testFixtureGeneration; }

if [[ -n "${1:-}" ]]; then
  "$1"
else
  test_IT1_cli_record
  test_IT2_source_links
  test_IT3_correction_review
  test_IT4_chunk_merge
  test_IT5_backend_selection
  test_IT6_fixture_generation
fi
