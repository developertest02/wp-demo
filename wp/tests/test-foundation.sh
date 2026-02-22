#!/usr/bin/env bash
# test-foundation.sh - Tests for the foundation layer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Source common library
source "$WP_ROOT/lib/wp-common.sh"

# Test directory for isolated tests
TEST_SESSION_DIR="$WP_ROOT/test_session_$$"

# Cleanup function
cleanup() {
    if [[ -d "$TEST_SESSION_DIR" ]]; then
        rm -rf "$TEST_SESSION_DIR"
    fi
}
trap cleanup EXIT

# Create a test input file
setup_test_file() {
    mkdir -p "$TEST_SESSION_DIR"
    local test_file="$TEST_SESSION_DIR/test_input.txt"
    echo "Hello world this is a test file" > "$test_file"
    echo "$test_file"
}

# Test: wp init creates expected directory structure
test_init_creates_structure() {
    local test_file="$(setup_test_file)"
    export WP_SESSION="$TEST_SESSION_DIR/session"
    
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Check directory structure exists
    if [[ -d "$TEST_SESSION_DIR/session" ]]; then
        assert_eq "init creates session directory" "true" "true"
    else
        assert_eq "init creates session directory" "true" "false"
    fi
    
    if [[ -d "$TEST_SESSION_DIR/session/history" ]]; then
        assert_eq "init creates history directory" "true" "true"
    else
        assert_eq "init creates history directory" "true" "false"
    fi
    
    # Check first snapshot exists
    if [[ -f "$TEST_SESSION_DIR/session/history/0001.txt" ]]; then
        assert_eq "init creates 0001.txt snapshot" "true" "true"
    else
        assert_eq "init creates 0001.txt snapshot" "true" "false"
    fi
    
    # Check current symlink exists
    if [[ -L "$TEST_SESSION_DIR/session/current" ]]; then
        assert_eq "init creates current symlink" "true" "true"
    else
        assert_eq "init creates current symlink" "true" "false"
    fi
    
    # Check meta file exists and has correct format
    if [[ -f "$TEST_SESSION_DIR/session/meta" ]]; then
        assert_eq "init creates meta file" "true" "true"
    else
        assert_eq "init creates meta file" "true" "false"
    fi
    
    # Verify meta content
    local seq_line="$(grep '^seq=' "$TEST_SESSION_DIR/session/meta")"
    assert_eq "meta has seq=0001" "seq=0001" "$seq_line"
}

# Test: wp init fails with non-existent file
test_init_fails_nonexistent() {
    export WP_SESSION="$TEST_SESSION_DIR/session_nonexistent"
    
    local exit_code=0
    "$WP_ROOT/bin/wp" init "$TEST_SESSION_DIR/nonexistent.txt" 2>/dev/null || exit_code=$?
    
    assert_exit_code "init fails with non-existent file" 1 "$exit_code"
}

# Test: wp_commit increments sequence correctly
test_commit_increments_sequence() {
    local test_file="$(setup_test_file)"
    export WP_SESSION="$TEST_SESSION_DIR/session_commit"
    
    # Initialize
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Commit new content using pipe and wp_commit directly
    echo "New content for commit" | (
        source "$WP_ROOT/lib/wp-common.sh"
        wp_commit
    )
    
    # Check sequence incremented
    local seq_line="$(grep '^seq=' "$TEST_SESSION_DIR/session_commit/meta")"
    assert_eq "commit increments to seq=0002" "seq=0002" "$seq_line"
    
    # Check new snapshot exists
    if [[ -f "$TEST_SESSION_DIR/session_commit/history/0002.txt" ]]; then
        assert_eq "commit creates 0002.txt snapshot" "true" "true"
    else
        assert_eq "commit creates 0002.txt snapshot" "true" "false"
    fi
}

# Test: wp_current fails gracefully when no session exists
test_current_fails_no_session() {
    export WP_SESSION="$TEST_SESSION_DIR/session_noexist"
    
    local exit_code=0
    local output=""
    output="$(wp_current 2>&1)" || exit_code=$?
    
    assert_exit_code "current fails with no session" 1 "$exit_code"
    assert_contains "current error message mentions init" "$output" "wp init"
}

# Test: wp save writes the correct content
test_save_writes_content() {
    local test_file="$(setup_test_file)"
    export WP_SESSION="$TEST_SESSION_DIR/session_save"
    
    # Initialize
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Save to new file
    local save_file="$TEST_SESSION_DIR/saved.txt"
    "$WP_ROOT/bin/wp" save "$save_file"
    
    # Compare content
    local original_content="$(cat "$test_file")"
    local saved_content="$(cat "$save_file")"
    assert_eq "save writes correct content" "$original_content" "$saved_content"
}

# Test: wp clean removes the session directory
test_clean_removes_session() {
    local test_file="$(setup_test_file)"
    export WP_SESSION="$TEST_SESSION_DIR/session_clean"
    
    # Initialize
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Verify session exists
    if [[ -d "$TEST_SESSION_DIR/session_clean" ]]; then
        assert_eq "session exists before clean" "true" "true"
    else
        assert_eq "session exists before clean" "true" "false"
    fi
    
    # Clean (auto-confirm)
    echo "y" | "$WP_ROOT/bin/wp" clean
    
    # Verify session removed
    if [[ ! -d "$TEST_SESSION_DIR/session_clean" ]]; then
        assert_eq "clean removes session directory" "true" "true"
    else
        assert_eq "clean removes session directory" "true" "false"
    fi
}

# Test: wp_seq returns correct sequence
test_seq_returns_correct() {
    local test_file="$(setup_test_file)"
    export WP_SESSION="$TEST_SESSION_DIR/session_seq"
    
    # Initialize
    "$WP_ROOT/bin/wp" init "$test_file"
    
    # Source library only once (already sourced at top level)
    local seq="$(wp_seq)"
    assert_eq "seq returns 1 after init" "1" "$seq"
}

# Test: wp_log outputs to stderr with colors
test_log_outputs_stderr() {
    local output=""
    local stderr_output=""
    
    stderr_output="$(wp_log INFO "test message" 2>&1 >/dev/null)"
    assert_contains "log INFO format" "$stderr_output" "[INFO]"
    
    stderr_output="$(wp_log WARN "test message" 2>&1 >/dev/null)"
    assert_contains "log WARN format" "$stderr_output" "[WARN]"
    
    stderr_output="$(wp_log ERR "test message" 2>&1 >/dev/null)"
    assert_contains "log ERR format" "$stderr_output" "[ERR]"
}

# Test: wp_escape_sed escapes special characters
test_escape_sed() {
    local result=""
    
    result="$(wp_escape_sed "hello/world")"
    assert_eq "escape_sed escapes /" "hello\/world" "$result"
    
    result="$(wp_escape_sed "test.dots")"
    assert_eq "escape_sed escapes ." "test\.dots" "$result"
    
    result="$(wp_escape_sed "test[brackets]")"
    assert_eq "escape_sed escapes []" "test\[brackets\]" "$result"
}

# Test: wp_require_cmd fails for missing commands
test_require_cmd_fails_missing() {
    local exit_code=0
    (wp_require_cmd "nonexistent_command_12345") 2>/dev/null || exit_code=$?
    assert_exit_code "require_cmd fails for missing command" 127 "$exit_code"
}

# Test: wp_require_cmd succeeds for existing commands
test_require_cmd_succeeds_existing() {
    local exit_code=0
    (wp_require_cmd "echo" "cat") 2>/dev/null || exit_code=$?
    assert_exit_code "require_cmd succeeds for existing commands" 0 "$exit_code"
}

# Run all tests
main() {
    echo "=== Running Foundation Tests ==="
    echo ""
    
    test_init_creates_structure
    test_init_fails_nonexistent
    test_commit_increments_sequence
    test_current_fails_no_session
    test_save_writes_content
    test_clean_removes_session
    test_seq_returns_correct
    test_log_outputs_stderr
    test_escape_sed
    test_require_cmd_fails_missing
    test_require_cmd_succeeds_existing
    
    report
}

main "$@"
