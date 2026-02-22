#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/spell_unique_test_harness.sh"

# Test 1: Basic duplicates (cat, cat, dog -> cat, dog)
result=$(printf 'cat\ncat\ndog\n' | bash "$SCRIPT_DIR/../bin/spell/wp-spell-unique")
expected=$'cat\ndog'
assert_eq "basic duplicates" "$expected" "$result"

# Test 2: Same word repeated (the, the, the -> the)
result=$(printf 'the\nthe\nthe\n' | bash "$SCRIPT_DIR/../bin/spell/wp-spell-unique")
expected='the'
assert_eq "same word repeated" "$expected" "$result"

# Test 3: No duplicates (apple, berry, cat -> unchanged)
result=$(printf 'apple\nberry\ncat\n' | bash "$SCRIPT_DIR/../bin/spell/wp-spell-unique")
expected=$'apple\nberry\ncat'
assert_eq "no duplicates" "$expected" "$result"

# Test 4: Single word repeated 100 times
input=$(printf 'word\n%.0s' {1..100})
result=$(printf '%s' "$input" | bash "$SCRIPT_DIR/../bin/spell/wp-spell-unique")
expected='word'
assert_eq "word repeated 100 times" "$expected" "$result"

# Test 5: Empty input
result=$(printf '' | bash "$SCRIPT_DIR/../bin/spell/wp-spell-unique")
expected=''
assert_eq "empty input" "$expected" "$result"

report
