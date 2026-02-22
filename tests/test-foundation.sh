#!/usr/bin/env bash
# tests/test-foundation.sh - Tests for the foundation layer
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

# ============================================
# Test: wp init creates expected directory structure
# ============================================
test_init_structure() {
    local test_session="$TEMP_DIR/test_init_session"
    export WP_SESSION="$test_session"
    
    local test_file
    test_file=$(create_test_file "Hello World" "source.txt")
    
    # Run init
    "$PROJECT_ROOT/bin/wp" init "$test_file" 2>/dev/null
    
    # Check directory structure
    if [[ -d "$test_session" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: wp init creates session directory"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: wp init creates session directory"
        echo "  Directory does not exist: $test_session"
        ((TESTS_FAILED++)) || true
    fi
    
    assert_file_exists "wp init creates history directory" "$test_session/history"
    assert_file_exists "wp init creates meta file" "$test_session/meta"
    assert_file_exists "wp init creates 0001.txt snapshot" "$test_session/history/0001.txt"
    assert_symlink "wp init creates current symlink" "$test_session/current" "$test_session/history/0001.txt"
}

# ============================================
# Test: wp init fails with nonexistent file
# ============================================
test_init_nonexistent() {
    local test_session="$TEMP_DIR/test_init_nonexistent"
    export WP_SESSION="$test_session"
    
    local exit_code=0
    "$PROJECT_ROOT/bin/wp" init "$test_session/nonexistent.txt" 2>/dev/null || exit_code=$?
    
    assert_exit_code "wp init fails with nonexistent file" 1 "$exit_code"
}

# ============================================
# Test: wp_commit increments sequence correctly
# ============================================
test_commit_sequence() {
    local test_session="$TEMP_DIR/test_commit_session"
    export WP_SESSION="$test_session"

    local test_file
    test_file=$(create_test_file "Initial content" "source.txt")

    # Initialize session
    "$PROJECT_ROOT/bin/wp" init "$test_file"

    # Verify initial sequence
    local seq
    seq=$("$PROJECT_ROOT/bin/wp" status | grep "Snapshot:" | awk '{print $2}')
    assert_eq "Initial sequence is 0001" "0001" "$seq"

    # Commit a new snapshot
    echo "Second content" | wp_commit

    # Verify sequence incremented
    seq=$("$PROJECT_ROOT/bin/wp" status | grep "Snapshot:" | awk '{print $2}')
    assert_eq "Sequence increments to 0002" "0002" "$seq"

    # Verify history file exists
    assert_file_exists "0002.txt snapshot created" "$test_session/history/0002.txt"
}

# ============================================
# Test: wp_current fails gracefully when no session exists
# ============================================
test_current_no_session() {
    local test_session="$TEMP_DIR/test_no_session"
    export WP_SESSION="$test_session"

    local exit_code=0
    (wp_current 2>/dev/null) || exit_code=$?

    assert_exit_code "wp_current fails without session" 1 "$exit_code"
}

# ============================================
# Test: wp_save writes the correct content
# ============================================
test_save_content() {
    local test_session="$TEMP_DIR/test_save_session"
    export WP_SESSION="$test_session"
    
    local test_file
    test_file=$(create_test_file "Save me content" "source.txt")
    
    # Initialize session
    "$PROJECT_ROOT/bin/wp" init "$test_file"
    
    # Save to a new file
    local save_file="$TEMP_DIR/saved_output.txt"
    "$PROJECT_ROOT/bin/wp" save "$save_file"
    
    # Verify content
    assert_file_content "wp save writes correct content" "$save_file" "Save me content"
}

# ============================================
# Test: wp_clean removes the session directory
# ============================================
test_clean() {
    local test_session="$TEMP_DIR/test_clean_session"
    export WP_SESSION="$test_session"
    
    local test_file
    test_file=$(create_test_file "Clean me" "source.txt")
    
    # Initialize session
    "$PROJECT_ROOT/bin/wp" init "$test_file"
    
    # Verify session exists
    assert_file_exists "Session exists before clean" "$test_session"
    
    # Clean (use yes to auto-confirm)
    yes | "$PROJECT_ROOT/bin/wp" clean &>/dev/null || true
    
    # Verify session removed
    if [[ -d "$test_session" ]]; then
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: wp_clean removes session directory"
        ((TESTS_FAILED++)) || true
    else
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: wp_clean removes session directory"
        ((TESTS_PASSED++)) || true
    fi
}

# ============================================
# Test: wp_seq returns correct sequence
# ============================================
test_wp_seq() {
    local test_session="$TEMP_DIR/test_seq_session"
    export WP_SESSION="$test_session"
    
    local test_file
    test_file=$(create_test_file "Seq test" "source.txt")
    
    # Initialize session
    "$PROJECT_ROOT/bin/wp" init "$test_file"
    
    # Check sequence via wp_seq function
    local seq
    seq=$(wp_seq)
    assert_eq "wp_seq returns 1 after init" "1" "$seq"
    
    # Commit another snapshot
    echo "More content" | wp_commit 2>/dev/null
    
    seq=$(wp_seq)
    assert_eq "wp_seq returns 2 after second commit" "2" "$seq"
}

# ============================================
# Test: wp_log outputs to stderr with colors
# ============================================
test_wp_log() {
    local output
    output=$(wp_log INFO "test message" 2>&1)

    assert_contains "wp_log INFO includes level" "$output" "[INFO]"
    assert_contains "wp_log INFO includes message" "$output" "test message"
}

# ============================================
# Test: wp_require_cmd fails for missing commands
# ============================================
test_wp_require_cmd() {
    local exit_code=0
    (wp_require_cmd "nonexistent_command_xyz" 2>/dev/null) || exit_code=$?

    assert_exit_code "wp_require_cmd exits 127 for missing command" 127 "$exit_code"
}

# ============================================
# Test: wp_escape_sed escapes special characters
# ============================================
test_wp_escape_sed() {
    local escaped
    escaped=$(wp_escape_sed "hello/world.test[abc]*def^ghi\$jkl\\mno")

    # Check that special chars are escaped
    assert_contains "wp_escape_sed escapes /" "$escaped" "\/"
    assert_contains "wp_escape_sed escapes ." "$escaped" "\\."
    assert_contains "wp_escape_sed escapes [" "$escaped" "\\["
}

# ============================================
# Test: wp pipe outputs current snapshot
# ============================================
test_wp_pipe() {
    local test_session="$TEMP_DIR/test_pipe_session"
    export WP_SESSION="$test_session"
    
    local test_file
    test_file=$(create_test_file "Pipe output test" "source.txt")
    
    # Initialize session
    "$PROJECT_ROOT/bin/wp" init "$test_file"
    
    # Run pipe
    local output
    output=$("$PROJECT_ROOT/bin/wp" pipe)
    
    assert_eq "wp pipe outputs current snapshot" "Pipe output test" "$output"
}

# ============================================
# Test: wp status shows correct info
# ============================================
test_wp_status() {
    local test_session="$TEMP_DIR/test_status_session"
    export WP_SESSION="$test_session"
    
    local test_file
    test_file=$(create_test_file "Status test content here" "source.txt")
    
    # Initialize session
    "$PROJECT_ROOT/bin/wp" init "$test_file"
    
    # Run status
    local output
    output=$("$PROJECT_ROOT/bin/wp" status)
    
    assert_contains "wp status shows source" "$output" "Source:"
    assert_contains "wp status shows snapshot" "$output" "Snapshot:"
    assert_contains "wp status shows word count" "$output" "Word count:"
}

# ============================================
# Run all tests
# ============================================
echo "=== Foundation Tests ==="
echo ""

test_init_structure
test_init_nonexistent
test_commit_sequence
test_current_no_session
test_save_content
test_clean
test_wp_seq
test_wp_log
test_wp_require_cmd
test_wp_escape_sed
test_wp_pipe
test_wp_status

report
