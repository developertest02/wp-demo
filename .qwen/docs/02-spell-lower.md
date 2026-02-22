# Task 02 — `wp-spell-lower` (Spell Pipeline Stage 2: Normalizer)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 03, 04, 05, 06, 07.
Requires task 00 (Foundation) to be complete before integration (task 08).

## Objective
Implement `bin/spell/wp-spell-lower` — the second stage of the spell-check pipeline.
It reads a list of words (one per line) from stdin and emits all words converted to
lowercase on stdout.

---

## Rationale
Dictionaries store words in lowercase. Without normalization, correctly spelled words
that appear at the start of sentences ("The", "A") or as proper nouns ("Unix", "Bell")
would be flagged as misspellings. This stage ensures all tokens are in a canonical
form before dictionary comparison.

---

## Behavior

### Input
One word per line (output of `wp-spell-words`). May be mixed case.

### Output
One word per line, all characters converted to lowercase.
Line count in == line count out. No lines are added or removed.

### Examples

```
Input:          Output:
The             the
Quick           quick
Brown           brown
UNIX            unix
```

---

## Implementation

### Backing tool
`tr`

### Implementation
```bash
tr 'A-Z' 'a-z'
```

This is intentionally the simplest possible implementation.
Do not use `awk`, `sed`, or `python` — `tr` is the correct tool for this job.

---

## File Location
`bin/spell/wp-spell-lower`

Must be executable (`chmod +x`).

---

## Script skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail
tr 'A-Z' 'a-z'
```

---

## Test File
`tests/test-spell-lower.sh`

### Required test cases

| # | Input | Expected output |
|---|---|---|
| 1 | `Hello` | `hello` |
| 2 | `UNIX` | `unix` |
| 3 | `already` | `already` |
| 4 | `MiXeD` | `mixed` |
| 5 | empty string | no output, exit 0 |
| 6 | three words on three lines | three lowercase words on three lines |

All tests must use `source tests/harness.sh` and call `report` at the end.

---

## Acceptance Criteria
- `bash tests/test-spell-lower.sh` exits 0, all cases PASS
- Script is ≤ 5 lines including shebang and set flags
- Script produces no output to stderr during normal operation
- Line count of input equals line count of output for non-empty input
