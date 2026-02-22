#!/usr/bin/env bash
# Test suite for wp-spell-mismatch
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SPELL_MISMATCH="$PROJECT_DIR/bin/spell/wp-spell-mismatch"
TEST_DICT="$PROJECT_DIR/tests/fixtures/test-dict.txt"
TEMP_DICT=""

# Source test harness
source "$SCRIPT_DIR/spell_mismatch_test_harness.sh"

# Setup: create a temp copy of test dictionary for -a flag tests
setup() {
    TEMP_DICT=$(mktemp)
    cp "$TEST_DICT" "$TEMP_DICT"
}

# Cleanup temp files
teardown() {
    if [ -n "$TEMP_DICT" ] && [ -f "$TEMP_DICT" ]; then
        rm -f "$TEMP_DICT"
    fi
}

trap teardown EXIT

# Test 1: All words in dictionary - no output, exit 0
test_all_words_in_dictionary() {
    local output
    local exit_code
    
    output=$(echo -e "cat\ndog\nfox" | "$SPELL_MISMATCH" -d "$TEST_DICT" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    assert_exit_code "Test 1: All words in dictionary - exit code" "0" "$exit_code"
    assert_eq "Test 1: All words in dictionary - no output" "" "$output"
}

# Test 2: One misspelled word "kittne" - outputs "kittne"
test_one_misspelled_word() {
    local output
    local exit_code
    
    output=$(echo "kittne" | "$SPELL_MISMATCH" -d "$TEST_DICT" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    assert_exit_code "Test 2: One misspelled word - exit code" "0" "$exit_code"
    assert_eq "Test 2: One misspelled word - outputs kittne" "kittne" "$output"
}

# Test 3: Two misspelled words - both output, one per line
test_two_misspelled_words() {
    local output
    local exit_code
    
    output=$(echo -e "kittne\npuppie" | "$SPELL_MISMATCH" -d "$TEST_DICT" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    assert_exit_code "Test 3: Two misspelled words - exit code" "0" "$exit_code"
    assert_eq "Test 3: Two misspelled words - outputs both" "kittne
puppie" "$output"
}

# Test 4: Empty input - no output, exit 0
test_empty_input() {
    local output
    local exit_code
    
    output=$(echo "" | "$SPELL_MISMATCH" -d "$TEST_DICT" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    assert_exit_code "Test 4: Empty input - exit code" "0" "$exit_code"
    assert_eq "Test 4: Empty input - no output" "" "$output"
}

# Test 5: -a flag adds word to dictionary
test_a_flag_adds_word() {
    local output_before
    local output_after
    local exit_code
    
    # First verify the word is flagged as misspelled
    output_before=$(echo "zebra" | "$SPELL_MISMATCH" -d "$TEMP_DICT" 2>&1) || exit_code=$?
    
    assert_eq "Test 5a: Word not in dictionary initially" "zebra" "$output_before"
    
    # Add the word using -a flag
    "$SPELL_MISMATCH" -d "$TEMP_DICT" -a "zebra"
    
    # Now verify it's no longer flagged
    output_after=$(echo "zebra" | "$SPELL_MISMATCH" -d "$TEMP_DICT" 2>&1) || exit_code=$?
    
    assert_eq "Test 5b: Word added to dictionary - no longer flagged" "" "$output_after"
}

# Test 6: -d flag uses alternate dictionary
test_d_flag_alternate_dict() {
    local output
    local exit_code
    
    # Create a minimal alternate dictionary
    local alt_dict
    alt_dict=$(mktemp)
    echo "foreign" > "$alt_dict"
    echo "only" >> "$alt_dict"
    echo "words" >> "$alt_dict"
    sort -o "$alt_dict" "$alt_dict"
    
    # Test with alternate dictionary - input must be sorted for comm
    output=$(echo -e "foreign\nonly\nwords\nzebra" | "$SPELL_MISMATCH" -d "$alt_dict" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    assert_exit_code "Test 6: -d flag alternate dictionary - exit code" "0" "$exit_code"
    assert_eq "Test 6: -d flag alternate dictionary - only zebra output" "zebra" "$output"
    
    rm -f "$alt_dict"
}

# Run all tests
setup
test_all_words_in_dictionary
test_one_misspelled_word
test_two_misspelled_words
test_empty_input
test_a_flag_adds_word
test_d_flag_alternate_dict
report
