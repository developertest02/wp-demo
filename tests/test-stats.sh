#!/usr/bin/env bash
set -euo pipefail

# tests/test-stats.sh - Test cases for wp-stats

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BIN="$ROOT_DIR/bin/wp-stats"
FIXTURE="$ROOT_DIR/tests/fixtures/sample.txt"

# Source test harness
source "$SCRIPT_DIR/stats_test_harness.sh"

# Test 1: Known input, -w flag (word count)
test_word_count() {
    local result
    result=$("$BIN" -w "$FIXTURE")
    assert_eq "Word count with -w flag" "45" "$result"
}

# Test 2: Known input, -l flag (line count)
test_line_count() {
    local result
    result=$("$BIN" -l "$FIXTURE")
    assert_eq "Line count with -l flag" "4" "$result"
}

# Test 3: Known input, -s flag (sentence count)
test_sentence_count() {
    local result
    result=$("$BIN" -s "$FIXTURE")
    assert_eq "Sentence count with -s flag" "6" "$result"
}

# Test 4: Known input, -p flag (paragraph count)
test_paragraph_count() {
    local result
    result=$("$BIN" -p "$FIXTURE")
    assert_eq "Paragraph count with -p flag" "3" "$result"
}

# Test 5: --freq 3 on known input (top 3 non-stopwords)
test_word_frequency() {
    local result
    result=$("$BIN" --freq 3 "$FIXTURE")
    # Check that output contains 3 lines with word counts
    local line_count
    line_count=$(echo "$result" | grep -c . || echo 0)
    assert_eq "Frequency output has 3 entries" "3" "$line_count"
}

# Test 6: Empty input (outputs zeros, exits 0)
test_empty_input() {
    local result exit_code
    result=$(echo -n "" | "$BIN" -w) || exit_code=$?
    exit_code=${exit_code:-0}
    assert_exit_code "Empty input exits 0" "0" "$exit_code"
    assert_eq "Empty input word count is 0" "0" "$result"
}

# Test 7: Single word, no newline (word count = 1)
test_single_word_no_newline() {
    local result
    result=$(echo -n "hello" | "$BIN" -w)
    assert_eq "Single word without newline has count 1" "1" "$result"
}

# Run all tests
test_word_count
test_line_count
test_sentence_count
test_paragraph_count
test_word_frequency
test_empty_input
test_single_word_no_newline

report
