#!/usr/bin/env bash
# test-spell-integration.sh - Integration tests for wp-spell pipeline
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Setup test environment
TEST_SESSION_DIR=$(mktemp -d)
export WP_SESSION="$TEST_SESSION_DIR"
TEST_DICT=$(mktemp)

# Copy dictionary for testing
cp "$PROJECT_DIR/lib/dictionary.txt" "$TEST_DICT"

cleanup() {
    rm -rf "$TEST_SESSION_DIR" "$TEST_DICT"
}
trap cleanup EXIT

# Helper to run wp-spell with test dictionary
run_spell() {
    "$PROJECT_DIR/bin/spell/wp-spell" -d "$TEST_DICT" "$@"
}

echo "=== Test 1: Document with no misspellings ==="
echo "The quick brown fox jumps over the lazy dog." > /tmp/test_clean.txt
OUTPUT=$(run_spell /tmp/test_clean.txt)
if [[ -z "$OUTPUT" ]]; then
    echo "PASS: No output for clean document"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "FAIL: Expected no output, got: $OUTPUT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "=== Test 2: Document with 2 known misspellings ==="
echo "The kittne sat on the matt." > /tmp/test_misspell.txt
OUTPUT=$(run_spell /tmp/test_misspell.txt)
assert_contains "kittne flagged" "$OUTPUT" "kittne"
assert_contains "matt flagged" "$OUTPUT" "matt"

echo ""
echo "=== Test 3: Misspelled word in mixed case ==="
echo "The KiTtNe sat on the MaTt." > /tmp/test_case.txt
OUTPUT=$(run_spell /tmp/test_case.txt)
assert_contains "mixed case kittne flagged" "$OUTPUT" "kittne"
assert_contains "mixed case matt flagged" "$OUTPUT" "matt"

echo ""
echo "=== Test 4: Word added via -a, re-run ==="
# First verify the word is flagged
echo "This is a blurg word." > /tmp/test_add.txt
OUTPUT_BEFORE=$(run_spell /tmp/test_add.txt)
assert_contains "blurg flagged before add" "$OUTPUT_BEFORE" "blurg"

# Add the word to dictionary
run_spell -d "$TEST_DICT" -a "blurg" >/dev/null

# Re-run spell check
OUTPUT_AFTER=$(run_spell /tmp/test_add.txt)
if [[ -z "$OUTPUT_AFTER" ]]; then
    echo "PASS: blurg no longer flagged after adding to dictionary"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "FAIL: blurg still flagged: $OUTPUT_AFTER"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "=== Test 5: --count on document with 2 errors ==="
# Create a fresh test dictionary without blurg for this test
TEST_DICT2=$(mktemp)
grep -v "^blurg$" "$PROJECT_DIR/lib/dictionary.txt" > "$TEST_DICT2" || true

# Use words that are in the dictionary (the, is, it, was, are in dictionary)
echo "The kittne is a blurg." > /tmp/test_count.txt
OUTPUT=$( "$PROJECT_DIR/bin/spell/wp-spell" -d "$TEST_DICT2" --count /tmp/test_count.txt)
assert_eq "count returns 2" "2" "$OUTPUT"
rm -f "$TEST_DICT2"

echo ""
echo "=== Test 6: Piped input with misspelling ==="
OUTPUT=$(echo "The kittne sat" | "$PROJECT_DIR/bin/spell/wp-spell" -d "$TEST_DICT")
assert_contains "piped input catches kittne" "$OUTPUT" "kittne"

echo ""
echo "=== Test 7: Full pipeline manual invocation ==="
OUTPUT=$(echo "The kittne is on the matt" \
  | "$PROJECT_DIR/bin/spell/wp-spell-words" \
  | "$PROJECT_DIR/bin/spell/wp-spell-lower" \
  | sort \
  | "$PROJECT_DIR/bin/spell/wp-spell-unique" \
  | "$PROJECT_DIR/bin/spell/wp-spell-mismatch" -d "$TEST_DICT")

assert_contains "manual pipeline catches kittne" "$OUTPUT" "kittne"
assert_contains "manual pipeline catches matt" "$OUTPUT" "matt"

# Verify common words are NOT in output (the, is, on are in dictionary)
if [[ "$OUTPUT" != *"the"* ]] && [[ "$OUTPUT" != *"is"* ]] && [[ "$OUTPUT" != *"on"* ]]; then
    echo "PASS: common words (the, is, on) not in output"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "FAIL: common words should not be flagged: $OUTPUT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
report
