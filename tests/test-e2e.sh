#!/usr/bin/env bash
# test-e2e.sh - End-to-end session integration test
# Simulates a full editing session using all tools together
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Setup test environment
TEST_SESSION_DIR=$(mktemp -d)
export WP_SESSION="$TEST_SESSION_DIR"
TEST_DOC="/tmp/test-doc-e2e.txt"

cleanup() {
    rm -rf "$TEST_SESSION_DIR" "$TEST_DOC"
}
trap cleanup EXIT

# Create test document
echo "The kittne sat on the matt. It was a grate day." > "$TEST_DOC"

echo "=== E2E Test: Full editing session ==="
echo ""

# Setup: Initialize session
echo "--- Initializing session ---"
"$PROJECT_DIR/bin/wp" init "$TEST_DOC"

# Spell check: Verify misspellings are caught
echo "--- Running spell check ---"
ERRORS=$("$PROJECT_DIR/bin/wp" pipe | "$PROJECT_DIR/bin/spell/wp-spell")
assert_contains "e2e: kittne flagged" "$ERRORS" "kittne"
assert_contains "e2e: matt flagged" "$ERRORS" "matt"
assert_contains "e2e: grate flagged" "$ERRORS" "grate"

# Verify initial sequence number
SEQ_BEFORE=$("$PROJECT_DIR/bin/wp" status | grep "Snapshot:" | awk '{print $2}')
assert_eq "e2e: initial seq is 1" "1" "$SEQ_BEFORE"

# Fix a word using wp-search
echo "--- Fixing 'kittne' to 'kitten' ---"
"$PROJECT_DIR/bin/wp" run "wp-search" "kittne" "kitten"

# Verify sequence incremented
SEQ_AFTER=$("$PROJECT_DIR/bin/wp" status | grep "Snapshot:" | awk '{print $2}')
assert_eq "e2e: seq incremented" "2" "$SEQ_AFTER"

# Verify fix: kittne should be gone
echo "--- Verifying fix ---"
ERRORS_AFTER=$("$PROJECT_DIR/bin/wp" pipe | "$PROJECT_DIR/bin/spell/wp-spell")
assert_not_contains "e2e: kittne resolved" "$ERRORS_AFTER" "kittne"
# matt and grate should still be there
assert_contains "e2e: matt still flagged" "$ERRORS_AFTER" "matt"
assert_contains "e2e: grate still flagged" "$ERRORS_AFTER" "grate"

# Stats: Check word count
echo "--- Checking stats ---"
WORDS=$("$PROJECT_DIR/bin/wp" pipe | "$PROJECT_DIR/bin/wp-stats" -w)
assert_eq "e2e: word count" "11" "$WORDS"

# Undo: Revert the change
echo "--- Undoing change ---"
"$PROJECT_DIR/bin/wp-undo"

# Verify sequence decremented
SEQ_UNDO=$("$PROJECT_DIR/bin/wp" status | grep "Snapshot:" | awk '{print $2}')
assert_eq "e2e: undo restores seq" "1" "$SEQ_UNDO"

# Verify original error is back after undo
echo "--- Verifying error back after undo ---"
ERRORS_UNDONE=$("$PROJECT_DIR/bin/wp" pipe | "$PROJECT_DIR/bin/spell/wp-spell")
assert_contains "e2e: error back after undo" "$ERRORS_UNDONE" "kittne"

echo ""
echo "=== All E2E tests completed ==="
report
