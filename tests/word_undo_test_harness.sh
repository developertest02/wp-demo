#!/usr/bin/env bash
# harness.sh - Test harness for wp tests
# Source this file in test scripts to use assertion functions

# Global counters
TESTS_PASSED=0
TESTS_FAILED=0

# ANSI color codes
HARNESS_COLOR_GREEN='\033[0;32m'
HARNESS_COLOR_RED='\033[0;31m'
HARNESS_COLOR_RESET='\033[0m'

# assert_eq
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
}

# assert_contains
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
        echo "  Expected substring: $needle"
        echo "  In: $haystack"
        ((TESTS_FAILED++)) || true
    fi
}

# assert_exit_code
# Usage: assert_exit_code "description" expected_code actual_code
assert_exit_code() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" -eq "$actual" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        ((TESTS_FAILED++)) || true
    fi
}

# assert_file_exists
# Usage: assert_file_exists "description" "filepath"
assert_file_exists() {
    local description="$1"
    local filepath="$2"
    
    if [[ -f "$filepath" ]]; then
        echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  File does not exist: $filepath"
        ((TESTS_FAILED++)) || true
    fi
}

# assert_file_equals
# Usage: assert_file_equals "description" "filepath" "expected_content"
assert_file_equals() {
    local description="$1"
    local filepath="$2"
    local expected="$3"
    
    if [[ -f "$filepath" ]]; then
        local actual
        actual="$(cat "$filepath")"
        if [[ "$expected" == "$actual" ]]; then
            echo -e "${HARNESS_COLOR_GREEN}PASS${HARNESS_COLOR_RESET}: $description"
            ((TESTS_PASSED++)) || true
        else
            echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
            echo "  Expected: $expected"
            echo "  Actual:   $actual"
            ((TESTS_FAILED++)) || true
        fi
    else
        echo -e "${HARNESS_COLOR_RED}FAIL${HARNESS_COLOR_RESET}: $description"
        echo "  File does not exist: $filepath"
        ((TESTS_FAILED++)) || true
    fi
}

# report
# Prints summary and exits with appropriate code
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
