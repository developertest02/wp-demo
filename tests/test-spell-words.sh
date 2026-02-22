#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/harness.sh"

SPELL_WORDS="$SCRIPT_DIR/../bin/spell/wp-spell-words"

# Test 1: Hello, world!
result=$(echo "Hello, world!" | bash "$SPELL_WORDS")
expected=$'Hello\nworld'
assert_eq "Hello, world!" "$expected" "$result"

# Test 2: time-sharing (hyphenated words split)
result=$(echo "time-sharing" | bash "$SPELL_WORDS")
expected=$'time\nsharing'
assert_eq "time-sharing" "$expected" "$result"

# Test 3: Chapter 12 (numbers discarded)
result=$(echo "Chapter 12" | bash "$SPELL_WORDS")
expected="Chapter"
assert_eq "Chapter 12" "$expected" "$result"

# Test 4: empty string (no output, exit 0)
exit_code=0
result=$(echo -n "" | bash "$SPELL_WORDS") || exit_code=$?
assert_eq "empty string output" "" "$result"
assert_exit_code "empty string exit code" 0 "$exit_code"

# Test 5: won't stop (contractions split)
result=$(echo "won't stop" | bash "$SPELL_WORDS")
expected=$'won\nt\nstop'
assert_eq "won't stop" "$expected" "$result"

# Test 6: ... (only punctuation, no output)
exit_code=0
result=$(echo "..." | bash "$SPELL_WORDS") || exit_code=$?
assert_eq "only punctuation" "" "$result"
assert_exit_code "only punctuation exit code" 0 "$exit_code"

report
