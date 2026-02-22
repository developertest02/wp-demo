# Task 01 — `wp-spell-words` (Spell Pipeline Stage 1: Tokenizer)

## Execution Order
**Parallel batch.** May run concurrently with tasks 02, 03, 04, 05, 06, 07.
Requires task 00 (Foundation) to be complete before integration (task 08).

## Objective
Implement `bin/spell/wp-spell-words` — the first stage of the spell-check pipeline.
It reads raw document text from stdin and emits one word token per line on stdout.

---

## Behavior

### Input
Raw document text on stdin. May include punctuation, numbers, mixed case, hyphens,
apostrophes, newlines, and blank lines.

### Output
One token per line. A token is a contiguous sequence of alphabetic characters `[A-Za-z]`.
Non-alphabetic characters are treated as delimiters and are **not** emitted.

### Rules
- Hyphenated words (e.g. `time-sharing`) are split into two tokens: `time`, `sharing`
- Contractions (e.g. `won't`) are split: `won`, `t`
- Numbers and tokens that contain only digits are discarded entirely
- Empty lines in output are not permitted
- The script must handle an empty input gracefully (produces no output, exits 0)

### Examples

```
Input:  "The quick-brown fox jumps over the lazy dog."
Output:
The
quick
brown
fox
jumps
over
the
lazy
dog
```

```
Input:  "Chapter 12: Unix time-sharing systems."
Output:
Chapter
Unix
time
sharing
systems
```

---

## Implementation

### Backing tools
`tr`, `grep`

### Recommended approach
```bash
tr -cs 'A-Za-z' '\n'   # replace all non-alpha runs with a single newline
grep -v '^$'            # remove any blank lines
```

The `-c` flag to `tr` complements the character class (everything except A-Za-z).
The `-s` flag squeezes consecutive delimiter characters into one, preventing blank
lines from runs of punctuation.

### Script skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail
tr -cs 'A-Za-z' '\n' | grep -v '^$'
```

The implementation should be minimal. Resist the urge to add complexity.

---

## File Location
`bin/spell/wp-spell-words`

Must be executable (`chmod +x`).

---

## Test File
`tests/test-spell-words.sh`

### Required test cases

| # | Input | Expected output |
|---|---|---|
| 1 | `Hello, world!` | `Hello` then `world` |
| 2 | `time-sharing` | `time` then `sharing` |
| 3 | `Chapter 12` | `Chapter` only (12 discarded) |
| 4 | empty string | no output, exit 0 |
| 5 | `won't stop` | `won`, `t`, `stop` |
| 6 | `...` | no output |

All tests must use `source tests/harness.sh` and call `report` at the end.

---

## Acceptance Criteria
- `bash tests/test-spell-words.sh` exits 0, all cases PASS
- Script produces no output to stderr during normal operation
- Script is ≤ 10 lines including shebang and set flags
