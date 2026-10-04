#!/usr/bin/env bash
set -euo pipefail

# The named cases were specified in the accepted design and use Swift Testing.
test_IT1_cli_record() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testCLIRecordOpen'; }
test_IT2_source_links() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testSourceLinks'; }
test_IT3_correction_review() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testCorrectionAndReview'; }
test_IT4_chunk_merge() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testChunkMerge'; }
test_IT5_backend_selection() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testBackendSelection'; }
test_IT6_fixture_generation() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testFixtureGeneration'; }
test_IT7_three_commands() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testThreeCommands'; }
test_IT8_neutral_summary() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testNeutralSummary'; }
test_IT9_failure_preserves_record() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testFailurePreservesRecord'; }
test_IT10_language_record() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testLanguageRecord'; }
test_IT11_evidence_first_cli() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testEvidenceFirstCLI'; }
test_IT12_validation_preserves_record() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testModelValidationFailurePreservesRecord'; }
test_IT13_multi_stage_cli() { swift test --filter 'MeetingIntegrationTests.MeetingIntegrationTests/testMultiStageCLI'; }

if [[ -n "${1:-}" ]]; then
  "$1"
else
  test_IT1_cli_record
  test_IT2_source_links
  test_IT3_correction_review
  test_IT4_chunk_merge
  test_IT5_backend_selection
  test_IT6_fixture_generation
  test_IT7_three_commands
  test_IT8_neutral_summary
  test_IT9_failure_preserves_record
  test_IT10_language_record
  test_IT11_evidence_first_cli
  test_IT12_validation_preserves_record
  test_IT13_multi_stage_cli
fi
