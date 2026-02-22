#!/usr/bin/env bash
# tests/word_search_test_harness.sh - Test harness for word processing tool tests
# Source this file in test scripts: source tests/word_search_test_harness.sh
set -uo pipefail

# Global counters
TESTS_PASSED=0
TESTS_FAILED=0

# ANSI color codes
readonly HARNESS_COLOR_GREEN='\033[0;32m'
readonly HARNESS_COLOR_RED='\033[0;31m'
readonly HARNESS_COLOR_RESET='\033[0m'

# assert_eq - Assert that EXPECTED equals ACTUAL
# Usage: assert_eq "description" "expected" "actual"
assert_eq() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++)) || true
    fi
    return 0
}

# assert_contains - Assert that HAYSTACK contains NEEDLE
# Usage: assert_contains "description" "haystack" "needle"
assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  Expected to contain: $needle"
        echo "  In: $haystack"
        ((TESTS_FAILED++)) || true
    fi
    return 0
}

# assert_exit_code - Assert that actual exit code matches expected
# Usage: assert_exit_code "description" expected_code actual_code
assert_exit_code() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        ((TESTS_FAILED++)) || true
    fi
    return 0
}

# assert_file_exists - Assert that a file exists
# Usage: assert_file_exists "description" "filepath"
assert_file_exists() {
    local description="$1"
    local filepath="$2"

    if [[ -f "$filepath" ]] || [[ -d "$filepath" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  File does not exist: $filepath"
        ((TESTS_FAILED++)) || true
    fi
    return 0
}

# assert_file_content - Assert that a file contains expected content
# Usage: assert_file_content "description" "filepath" "expected_content"
assert_file_content() {
    local description="$1"
    local filepath="$2"
    local expected="$3"
    
    if [[ ! -f "$filepath" ]]; then
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  File does not exist: $filepath"
        ((TESTS_FAILED++)) || true
        return 0
    fi
    
    local actual
    actual=$(cat "$filepath")
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++)) || true
    fi
    return 0
}

# assert_symlink - Assert that a symlink exists and points to the right target
# Usage: assert_symlink "description" "symlink_path" "expected_target"
assert_symlink() {
    local description="$1"
    local symlink="$2"
    local expected_target="$3"
    
    if [[ ! -L "$symlink" ]]; then
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  Not a symlink: $symlink"
        ((TESTS_FAILED++)) || true
        return 0
    fi
    
    local actual_target
    actual_target=$(readlink "$symlink")
    
    # Compare either the symlink path or resolved path
    if [[ "$actual_target" == "$expected_target" ]] || [[ "$(readlink -f "$symlink")" == "$(readlink -f "$expected_target")" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  Expected target: $expected_target"
        echo "  Actual target:   $actual_target"
        ((TESTS_FAILED++)) || true
    fi
    return 0
}

# report - Print test summary and exit with appropriate code
# Call this at the end of every test script
report() {
    echo ""
    echo "================================"
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "================================"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}
