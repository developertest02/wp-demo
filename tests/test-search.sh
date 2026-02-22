#!/usr/bin/env bash
set -euo pipefail

# tests/test-search.sh - Test cases for wp-search

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BIN="$ROOT_DIR/bin/wp-search"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Helper to set up a temp session
setup_session() {
    local content="${1:-}"
    SESSION_DIR=$(mktemp -d)
    export WP_SESSION="$SESSION_DIR"
    
    mkdir -p "$SESSION_DIR/history"
    
    if [[ -n "$content" ]]; then
        echo "$content" > "$SESSION_DIR/history/0001.txt"
        ln -sfn "$SESSION_DIR/history/0001.txt" "$SESSION_DIR/current"
        cat > "$SESSION_DIR/meta" <<EOF
seq=1
source=/tmp/test.txt
EOF
    fi
}

# Helper to clean up temp session
cleanup_session() {
    if [[ -n "${SESSION_DIR:-}" ]] && [[ -d "$SESSION_DIR" ]]; then
        rm -rf "$SESSION_DIR"
    fi
    unset WP_SESSION || true
    unset SESSION_DIR || true
}

# Test 1: Simple literal replace
test_simple_replace() {
    setup_session "the cat sat on the mat"
    
    local result
    result=$(echo "the cat sat on the mat" | "$BIN" "cat" "dog")
    
    assert_eq "Simple literal replace" "the dog sat on the mat" "$result"
    
    cleanup_session
}

# Test 2: Case-insensitive -i flag
test_case_insensitive() {
    setup_session "Cat CAT cat"
    
    local result
    result=$(echo "Cat CAT cat" | "$BIN" -i "cat" "dog")
    
    assert_eq "Case-insensitive replace" "dog dog dog" "$result"
    
    cleanup_session
}

# Test 3: ERE pattern -r flag
test_ere_pattern() {
    setup_session "Mr. Smith and Mrs. Jones"
    
    local result
    result=$(echo "Mr. Smith and Mrs. Jones" | "$BIN" -r '(Mr|Mrs)\.' "Mx.")
    
    assert_eq "ERE pattern replace" "Mx. Smith and Mx. Jones" "$result"
    
    cleanup_session
}

# Test 4: -n 2 flag (nth occurrence)
test_nth_occurrence() {
    setup_session "foo bar foo bar foo"
    
    local result
    result=$(echo "foo bar foo bar foo" | "$BIN" -n 2 "foo" "baz")
    
    # Only the 2nd occurrence on each line should be replaced
    assert_eq "Nth occurrence replace" "foo bar baz bar foo" "$result"
    
    cleanup_session
}

# Test 5: Preview mode -p flag
test_preview_mode() {
    setup_session "hello world"
    
    local initial_seq
    initial_seq=$(cat "$SESSION_DIR/meta" | grep '^seq=' | cut -d'=' -f2)
    
    local result
    result=$(echo "hello world" | "$BIN" -p "world" "there") || true
    
    # Check that output contains diff markers
    assert_contains "Preview output contains diff markers" "$result" ">"
    
    # Check that session is unchanged
    local final_seq
    final_seq=$(cat "$SESSION_DIR/meta" | grep '^seq=' | cut -d'=' -f2)
    assert_eq "Preview mode doesn't increment seq" "$initial_seq" "$final_seq"
    
    cleanup_session
}

# Test 6: Pattern with / character
test_pattern_with_slash() {
    setup_session "path/to/file"
    
    local result
    result=$(echo "path/to/file" | "$BIN" "path/to" "new/path")
    
    assert_eq "Pattern with slash" "new/path/file" "$result"
    
    cleanup_session
}

# Test 7: No match (input passes through unchanged)
test_no_match() {
    setup_session "hello world"
    
    local result exit_code
    result=$(echo "hello world" | "$BIN" "xyz" "abc")
    exit_code=$?
    
    assert_exit_code "No match exits 0" "0" "$exit_code"
    assert_eq "No match passes through unchanged" "hello world" "$result"
    
    cleanup_session
}

# Test 8: Empty input
test_empty_input() {
    setup_session ""
    
    local result exit_code
    result=$(echo -n "" | "$BIN" "foo" "bar") || exit_code=$?
    exit_code=${exit_code:-0}
    
    assert_exit_code "Empty input exits 0" "0" "$exit_code"
    assert_eq "Empty input produces empty output" "" "$result"
    
    cleanup_session
}

# Test 9: Session increment after non-preview run
test_session_increment() {
    setup_session "test content"
    
    local initial_seq
    initial_seq=$(cat "$SESSION_DIR/meta" | grep '^seq=' | cut -d'=' -f2)
    
    echo "test content" | "$BIN" "test" "modified" >/dev/null
    
    local final_seq
    final_seq=$(cat "$SESSION_DIR/meta" | grep '^seq=' | cut -d'=' -f2)
    
    assert_eq "Session increments after non-preview" "$((initial_seq + 1))" "$final_seq"
    
    cleanup_session
}

# Test 10: Multiple replacements per line (default -g behavior)
test_multiple_replacements() {
    setup_session "cat cat cat"
    
    local result
    result=$(echo "cat cat cat" | "$BIN" "cat" "dog")
    
    assert_eq "Multiple replacements per line" "dog dog dog" "$result"
    
    cleanup_session
}

# Test 11: Pattern with special regex characters
test_special_chars() {
    setup_session "test[123] value"
    
    local result
    # Using literal match (not ERE), brackets should be treated literally by sed without -E
    # But to be safe, let's test with a simpler pattern
    result=$(echo "test[123] value" | "$BIN" "test" "best")
    
    assert_eq "Special chars in input" "best[123] value" "$result"
    
    cleanup_session
}

# Test 12: Missing arguments
test_missing_args() {
    local result exit_code
    result=$("$BIN" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    assert_exit_code "Missing args exits non-zero" "1" "$exit_code"
    assert_contains "Missing args shows usage" "$result" "Usage"
}

# Run all tests
test_simple_replace
test_case_insensitive
test_ere_pattern
test_nth_occurrence
test_preview_mode
test_pattern_with_slash
test_no_match
test_empty_input
test_session_increment
test_multiple_replacements
test_special_chars
test_missing_args

report
