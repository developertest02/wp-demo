#!/usr/bin/env bash
# test-undo.sh - Tests for wp-undo functionality
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_DIR="$(dirname "$SCRIPT_DIR")"
export WP_SESSION=""

source "$WP_DIR/lib/wp-common.sh"
source "$SCRIPT_DIR/harness.sh"

# Test setup and cleanup
setup_test_session() {
    local test_dir
    test_dir="$(mktemp -d)"
    export WP_SESSION="$test_dir"
    
    # Create session structure
    mkdir -p "$test_dir/history"
    
    # Create multiple snapshots with different content
    echo "First snapshot content with some words" > "$test_dir/history/0001.txt"
    echo "Second snapshot with different words here" > "$test_dir/history/0002.txt"
    echo "Third snapshot has more content now" > "$test_dir/history/0003.txt"
    echo "Fourth snapshot added for testing" > "$test_dir/history/0004.txt"
    
    # Set current to snapshot 3
    ln -sfn "$test_dir/history/0003.txt" "$test_dir/current"
    
    # Write meta
    cat > "$test_dir/meta" <<EOF
seq=3
source=test.txt
EOF
}

cleanup_test_session() {
    if [[ -n "${WP_SESSION:-}" ]] && [[ -d "$WP_SESSION" ]]; then
        rm -rf "$WP_SESSION"
    fi
    export WP_SESSION=""
}

# Test 1: Step back once from snapshot 3
test_step_back_once() {
    setup_test_session
    
    "$WP_DIR/bin/wp-undo"
    local actual_seq
    actual_seq="$(wp_seq)"
    
    assert_eq "Step back once from snapshot 3" "2" "$actual_seq"
    
    cleanup_test_session
}

# Test 2: Step back -n 2 from snapshot 4
test_step_back_n() {
    setup_test_session
    
    # First set current to snapshot 4
    ln -sfn "$WP_SESSION/history/0004.txt" "$WP_SESSION/current"
    sed -i 's/^seq=.*/seq=4/' "$WP_SESSION/meta"
    
    "$WP_DIR/bin/wp-undo" -n 2
    local actual_seq
    actual_seq="$(wp_seq)"
    
    assert_eq "Step back -n 2 from snapshot 4" "2" "$actual_seq"
    
    cleanup_test_session
}

# Test 3: Step back from snapshot 1 (should fail)
test_step_back_at_oldest() {
    setup_test_session
    
    # Set current to snapshot 1
    ln -sfn "$WP_SESSION/history/0001.txt" "$WP_SESSION/current"
    sed -i 's/^seq=.*/seq=1/' "$WP_SESSION/meta"
    
    local exit_code=0
    "$WP_DIR/bin/wp-undo" 2>/dev/null || exit_code=$?
    
    assert_exit_code "Step back from snapshot 1 exits with error" "1" "$exit_code"
    
    # Verify session unchanged
    local actual_seq
    actual_seq="$(wp_seq)"
    assert_eq "Session unchanged after failed step back" "1" "$actual_seq"
    
    cleanup_test_session
}

# Test 4: --list shows all snapshots
test_list() {
    setup_test_session
    
    local output
    output="$("$WP_DIR/bin/wp-undo" --list)"
    
    # Check that output contains sequence numbers and word counts
    assert_contains "--list contains snapshot 0001" "$output" "[0001]"
    assert_contains "--list contains snapshot 0002" "$output" "[0002]"
    assert_contains "--list contains snapshot 0003" "$output" "[0003]"
    assert_contains "--list contains word count" "$output" "words"
    assert_contains "--list marks current snapshot" "$output" "current"
    
    cleanup_test_session
}

# Test 5: --jump 2 from snapshot 4
test_jump() {
    setup_test_session
    
    # First set current to snapshot 4
    ln -sfn "$WP_SESSION/history/0004.txt" "$WP_SESSION/current"
    sed -i 's/^seq=.*/seq=4/' "$WP_SESSION/meta"
    
    "$WP_DIR/bin/wp-undo" --jump 2
    local actual_seq
    actual_seq="$(wp_seq)"
    
    assert_eq "--jump 2 from snapshot 4" "2" "$actual_seq"
    
    cleanup_test_session
}

# Test 6: --jump to non-existent snapshot
test_jump_nonexistent() {
    setup_test_session
    
    local exit_code=0
    "$WP_DIR/bin/wp-undo" --jump 99 2>/dev/null || exit_code=$?
    
    assert_exit_code "--jump to non-existent snapshot exits with error" "1" "$exit_code"
    
    # Verify session unchanged
    local actual_seq
    actual_seq="$(wp_seq)"
    assert_eq "Session unchanged after failed jump" "3" "$actual_seq"
    
    cleanup_test_session
}

# Test 7: --diff 1 between two known snapshots
test_diff() {
    setup_test_session
    
    # Current is snapshot 3, diff with snapshot 2 (1 step back)
    local output
    output="$("$WP_DIR/bin/wp-undo" --diff 1)" || true
    
    # Diff output should contain markers like < or > or lines with differences
    assert_contains "--diff shows differences" "$output" "snapshot"
    
    cleanup_test_session
}

# Test 8: --diff when only one snapshot exists
test_diff_single_snapshot() {
    local test_dir
    test_dir="$(mktemp -d)"
    export WP_SESSION="$test_dir"
    
    # Create session with only one snapshot
    mkdir -p "$test_dir/history"
    echo "Only snapshot" > "$test_dir/history/0001.txt"
    ln -sfn "$test_dir/history/0001.txt" "$test_dir/current"
    echo "seq=1" > "$test_dir/meta"
    
    local exit_code=0
    local output
    output="$("$WP_DIR/bin/wp-undo" --diff 1 2>&1)" || exit_code=$?
    
    assert_exit_code "--diff with single snapshot exits 0" "0" "$exit_code"
    assert_contains "--diff with single snapshot shows message" "$output" "Nothing to diff"
    
    cleanup_test_session
}

# Test 9: --prune with confirmation
test_prune() {
    local test_dir
    test_dir="$(mktemp -d)"
    export WP_SESSION="$test_dir"
    
    # Create session with 5 snapshots
    mkdir -p "$test_dir/history"
    for i in 1 2 3 4 5; do
        echo "Snapshot $i content" > "$test_dir/history/$(printf '%04d' $i).txt"
    done
    ln -sfn "$test_dir/history/0005.txt" "$test_dir/current"
    echo "seq=5" > "$test_dir/meta"
    
    # Prune keeping only 2 most recent (should delete snapshots 1, 2, 3)
    echo "y" | "$WP_DIR/bin/wp-undo" --prune 2 >/dev/null
    
    # Verify snapshots 1, 2, 3 are deleted
    local files_remaining=0
    for f in "$test_dir/history"/*.txt; do
        if [[ -f "$f" ]]; then
            ((files_remaining++)) || true
        fi
    done
    
    assert_eq "--prune keeps correct number of snapshots" "2" "$files_remaining"
    
    # Verify remaining snapshots are 0004 and 0005
    assert_file_exists "--prune keeps snapshot 0004" "$test_dir/history/0004.txt"
    assert_file_exists "--prune keeps snapshot 0005" "$test_dir/history/0005.txt"
    
    cleanup_test_session
}

# Test 10: --prune with N >= total snapshot count
test_prune_nothing() {
    setup_test_session
    
    local output
    output="$("$WP_DIR/bin/wp-undo" --prune 10 2>&1)" || true
    
    assert_contains "--prune with N >= count shows message" "$output" "Nothing to prune"
    
    cleanup_test_session
}

# Test 11: --prune without confirmation (answered 'N')
test_prune_cancelled() {
    local test_dir
    test_dir="$(mktemp -d)"
    export WP_SESSION="$test_dir"
    
    # Create session with 3 snapshots
    mkdir -p "$test_dir/history"
    for i in 1 2 3; do
        echo "Snapshot $i content" > "$test_dir/history/$(printf '%04d' $i).txt"
    done
    ln -sfn "$test_dir/history/0003.txt" "$test_dir/current"
    echo "seq=3" > "$test_dir/meta"
    
    # Prune with 'N' response
    echo "n" | "$WP_DIR/bin/wp-undo" --prune 1 >/dev/null || true
    
    # Verify all snapshots still exist
    local files_remaining=0
    for f in "$test_dir/history"/*.txt; do
        if [[ -f "$f" ]]; then
            ((files_remaining++)) || true
        fi
    done
    
    assert_eq "--prune cancelled keeps all snapshots" "3" "$files_remaining"
    
    cleanup_test_session
}

# Run all tests
test_step_back_once
test_step_back_n
test_step_back_at_oldest
test_list
test_jump
test_jump_nonexistent
test_diff
test_diff_single_snapshot
test_prune
test_prune_nothing
test_prune_cancelled

report
