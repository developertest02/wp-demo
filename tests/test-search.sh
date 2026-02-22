#!/usr/bin/env bash
# tests/test-search.sh - Tests for wp-search functionality
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Source common library
source "$PROJECT_ROOT/lib/wp-common.sh"

# Create a temp directory for isolated session testing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Test helper: create a temp file with content
create_test_file() {
    local content="$1"
    local filename="$2"
    local filepath="$TEMP_DIR/$filename"
    echo "$content" > "$filepath"
    echo "$filepath"
}

# Test helper: initialize a session and return the session dir
init_test_session() {
    local session_name="$1"
    local content="$2"
    local test_session="$TEMP_DIR/$session_name"
    export WP_SESSION="$test_session"

    local test_file
    test_file=$(create_test_file "$content" "source.txt")
    "$PROJECT_ROOT/bin/wp" init "$test_file" 2>/dev/null
}

# ============================================
# Test 1: Simple literal replace
# ============================================
test_simple_replace() {
    init_test_session "test_simple" "The cat sat on the mat"

    # Run search and commit
    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" "cat" "dog" 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    assert_contains "Simple replace: output contains 'dog'" "$output" "dog"
    assert_contains "Simple replace: output does not contain 'cat'" "$output" "The dog sat"
}

# ============================================
# Test 2: Case-insensitive -i flag
# ============================================
test_case_insensitive() {
    init_test_session "test_ci" "Cat CAT cat"

    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" -i "cat" "dog" 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    # Count occurrences of 'dog' - should be 3
    local count
    count=$(echo "$output" | grep -o "dog" | wc -l)
    assert_eq "Case-insensitive: all 3 replaced" "3" "$count"
}

# ============================================
# Test 3: ERE pattern -r flag
# ============================================
test_ere_pattern() {
    init_test_session "test_ere" "Mr. Smith and Mrs. Jones"

    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" -r "(Mr|Mrs)\." "Mx" 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    assert_contains "ERE pattern: Mr. replaced" "$output" "Mx Smith"
    assert_contains "ERE pattern: Mrs. replaced" "$output" "Mx Jones"
}

# ============================================
# Test 4: -n 2 flag (nth occurrence)
# ============================================
test_nth_occurrence() {
    init_test_session "test_nth" "cat cat cat cat"

    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" -n 2 "cat" "dog" 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    # With -n 2, only the 2nd occurrence on each line is replaced
    assert_eq "Nth occurrence: 2nd cat replaced" "cat dog cat cat" "$output"
}

# ============================================
# Test 5: Preview mode -p flag
# ============================================
test_preview_mode() {
    init_test_session "test_preview" "Hello World"

    # Get initial sequence
    local initial_seq
    initial_seq=$(wp_seq)

    # Run in preview mode
    local output
    output=$(cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" -p "World" "Universe" 2>&1) || true

    # Output should contain diff markers
    assert_contains "Preview mode: shows diff" "$output" "World"
    assert_contains "Preview mode: shows diff" "$output" "Universe"

    # Sequence should be unchanged
    local final_seq
    final_seq=$(wp_seq)
    assert_eq "Preview mode: sequence unchanged" "$initial_seq" "$final_seq"
}

# ============================================
# Test 6: Pattern with / character
# ============================================
test_pattern_with_slash() {
    init_test_session "test_slash" "path/to/file.txt"

    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" "path/to" "new/path" 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    assert_contains "Slash pattern: replaced correctly" "$output" "new/path/file.txt"
}

# ============================================
# Test 7: No match - input passes through unchanged
# ============================================
test_no_match() {
    init_test_session "test_nomatch" "Hello World"

    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" "xyz" "abc" 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    assert_eq "No match: input unchanged" "Hello World" "$output"
}

# ============================================
# Test 8: Empty input
# ============================================
test_empty_input() {
    init_test_session "test_empty" ""

    local output
    output=$(echo "" | "$PROJECT_ROOT/bin/wp-search" "cat" "dog" 2>/dev/null) || true

    # Empty input should produce empty output
    if [[ -z "$output" ]] || [[ "$output" == "" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: Empty input: no output"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: Empty input: no output"
        echo "  Expected empty output, got: $output"
        ((TESTS_FAILED++)) || true
    fi
}

# ============================================
# Test 9: Missing arguments error
# ============================================
test_missing_args() {
    init_test_session "test_args" "test"

    local exit_code=0
    local output
    output=$("$PROJECT_ROOT/bin/wp-search" 2>&1) || exit_code=$?

    assert_exit_code "Missing args: exits with code 1" 1 "$exit_code"
    assert_contains "Missing args: shows usage/error" "$output" "Usage"
}

# ============================================
# Test 10: Commit increments sequence
# ============================================
test_commit_increments() {
    init_test_session "test_commit" "original text"

    local initial_seq
    initial_seq=$(wp_seq)

    # Run search (non-preview mode commits)
    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" "original" "modified" > /dev/null

    local final_seq
    final_seq=$(wp_seq)

    # Sequence should be incremented
    local expected_seq=$((initial_seq + 1))
    assert_eq "Commit increments sequence" "$expected_seq" "$final_seq"
}

# ============================================
# Test 11: Multiple replacements with -g
# ============================================
test_global_replace() {
    init_test_session "test_global" "foo foo foo"

    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" -g "foo" "bar" 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    assert_eq "Global replace: all occurrences" "bar bar bar" "$output"
}

# ============================================
# Test 12: Pattern with special regex chars
# ============================================
test_special_chars() {
    init_test_session "test_special" 'price: $100 [sale]'

    # Without -r, special chars should be treated literally (escaped)
    cat "$WP_SESSION/current" | "$PROJECT_ROOT/bin/wp-search" '\$100' '$200' 2>/dev/null

    local output
    output=$(cat "$WP_SESSION/current")

    assert_contains "Special chars: dollar sign handled" "$output" '$200'
}

# ============================================
# Run all tests
# ============================================
echo "=== Search Tests ==="
echo ""

test_simple_replace
test_case_insensitive
test_ere_pattern
test_nth_occurrence
test_preview_mode
test_pattern_with_slash
test_no_match
test_empty_input
test_missing_args
test_commit_increments
test_global_replace
test_special_chars

report
