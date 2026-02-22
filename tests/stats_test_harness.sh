#!/usr/bin/env bash
# tests/harness.sh - Test helper library for all test scripts
# Source this file in test scripts: source tests/harness.sh

# Global counters
TESTS_PASSED=0
TESTS_FAILED=0

# assert_eq DESCRIPTION EXPECTED ACTUAL
# Compares EXPECTED and ACTUAL, reports PASS/FAIL
assert_eq() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo "PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "FAIL: $description"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# assert_contains DESCRIPTION HAYSTACK NEEDLE
# Passes if NEEDLE is a substring of HAYSTACK
assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "FAIL: $description"
        echo "  Expected '$haystack' to contain '$needle'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# assert_exit_code DESCRIPTION EXPECTED_CODE ACTUAL_CODE
# Passes if exit codes match
assert_exit_code() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" -eq "$actual" ]]; then
        echo "PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "FAIL: $description"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# report
# Prints summary and exits with appropriate code
report() {
    echo ""
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    if [[ "$TESTS_FAILED" -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}
