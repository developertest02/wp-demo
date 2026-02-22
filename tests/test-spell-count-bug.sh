#!/usr/bin/env bash
# test-spell-count-bug.sh - Test for spell check count bug
# Verifies that "Helloo, my name is jim." reports only 1 misspelling (helloo)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Setup test environment with temporary dictionary
TEST_DICT=$(mktemp)
cp "$PROJECT_DIR/lib/dictionary.txt" "$TEST_DICT"

cleanup() {
    rm -f "$TEST_DICT"
}
trap cleanup EXIT

run_spell() {
    "$PROJECT_DIR/bin/spell/wp-spell" -d "$TEST_DICT" "$@"
}

echo "=== Test: Spell check count for 'Helloo, my name is jim.' ==="
echo ""

# Create test file
TEST_FILE=$(mktemp)
echo "Helloo, my name is jim." > "$TEST_FILE"

echo "Test file content: $(cat "$TEST_FILE")"
echo ""

# Test 1: Check the count of misspellings
echo "--- Test 1: Count should be 1 (only 'helloo' is misspelled) ---"
COUNT=$(run_spell --count "$TEST_FILE")
echo "Count returned: $COUNT"

# Test 2: Check which words are flagged
echo ""
echo "--- Test 2: Only 'helloo' should be flagged ---"
OUTPUT=$(run_spell "$TEST_FILE")
echo "Misspelled words: $OUTPUT"
echo ""

# Assertions
EXPECTED_COUNT=1
EXPECTED_WORDS="helloo"

if [[ "$COUNT" -eq "$EXPECTED_COUNT" ]]; then
    echo "PASS: Count is correct ($COUNT)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "FAIL: Expected count $EXPECTED_COUNT, got $COUNT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

if [[ "$OUTPUT" == "$EXPECTED_WORDS" ]]; then
    echo "PASS: Only 'helloo' is flagged"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "FAIL: Expected only 'helloo', got: $OUTPUT"
    echo "      Words 'my', 'name', 'is', 'jim' should be in dictionary"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

rm -f "$TEST_FILE"

echo ""
report
