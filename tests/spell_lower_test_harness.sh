#!/usr/bin/env bash
# Test harness for spell-check pipeline tests

PASSED=0
FAILED=0

report() {
    echo "Results: $PASSED passed, $FAILED failed"
    if [ "$FAILED" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

pass() {
    echo "PASS: $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "FAIL: $1"
    FAILED=$((FAILED + 1))
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local name="$3"
    
    if [ "$expected" = "$actual" ]; then
        pass "$name"
    else
        fail "$name (expected: '$expected', got: '$actual')"
    fi
}
