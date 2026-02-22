#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/spell_lower_test_harness.sh"

SCRIPT="$SCRIPT_DIR/../bin/spell/wp-spell-lower"

# Test 1: Simple word with capital letter
result=$(echo "Hello" | bash "$SCRIPT")
assert_equals "hello" "$result" "Test 1: Hello -> hello"

# Test 2: All uppercase word
result=$(echo "UNIX" | bash "$SCRIPT")
assert_equals "unix" "$result" "Test 2: UNIX -> unix"

# Test 3: Already lowercase word
result=$(echo "already" | bash "$SCRIPT")
assert_equals "already" "$result" "Test 3: already -> already"

# Test 4: Mixed case word
result=$(echo "MiXeD" | bash "$SCRIPT")
assert_equals "mixed" "$result" "Test 4: MiXeD -> mixed"

# Test 5: Empty string
result=$(echo -n "" | bash "$SCRIPT" || true)
assert_equals "" "$result" "Test 5: empty string -> no output"

# Test 6: Three words on three lines
input="Hello
WORLD
TeSt"
expected="hello
world
test"
result=$(echo "$input" | bash "$SCRIPT")
assert_equals "$expected" "$result" "Test 6: three words on three lines"

report
