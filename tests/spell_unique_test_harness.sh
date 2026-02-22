#!/usr/bin/env bash
# Test harness for wp-demo test scripts
# Source this file in your test script: source tests/harness.sh

TESTS_PASSED=0
TESTS_FAILED=0

assert_eq() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo "PASS: $description"
        ((TESTS_PASSED++)) || true
    else
        echo "FAIL: $description"
        echo "  Expected: $(printf '%q' "$expected")"
        echo "  Actual:   $(printf '%q' "$actual")"
        ((TESTS_FAILED++)) || true
    fi
}

assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "PASS: $description"
        ((TESTS_PASSED++)) || true
    else
        echo "FAIL: $description"
        echo "  Expected '$needle' to be in: $(printf '%q' "$haystack")"
        ((TESTS_FAILED++)) || true
    fi
}

assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    local actual_code="$3"

    if [[ "$expected_code" -eq "$actual_code" ]]; then
        echo "PASS: $description"
        ((TESTS_PASSED++)) || true
    else
        echo "FAIL: $description"
        echo "  Expected exit code: $expected_code"
        echo "  Actual exit code:   $actual_code"
        ((TESTS_FAILED++)) || true
    fi
}

report() {
    echo ""
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    if [[ "$TESTS_FAILED" -gt 0 ]]; then
        exit 1
    fi
    exit 0
}
