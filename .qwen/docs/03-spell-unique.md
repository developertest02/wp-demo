# Task 03 — `wp-spell-unique` (Spell Pipeline Stage 4: Deduplicator)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 04, 05, 06, 07.
Requires task 00 (Foundation) to be complete before integration (task 08).

## Note on Stage Numbering
This script is Stage 4 in the pipeline. Stage 3 is the system `sort` utility,
called directly — no wrapper script is needed for it.

Pipeline order: words → lower → **sort** → unique → mismatch

---

## Objective
Implement `bin/spell/wp-spell-unique` — the fourth stage of the spell-check pipeline.
It reads a sorted list of words (one per line) from stdin and emits the list with
consecutive duplicate lines removed.

---

## Rationale
Common words like "the" and "and" may appear hundreds of times in a document.
Checking each occurrence against the dictionary separately would be wasteful.
This stage ensures each unique word is checked exactly once.

**Important:** This stage only works correctly when its input is already sorted.
It relies on `sort` (Stage 3) having been applied immediately before it in the pipeline.
`uniq` only removes *adjacent* duplicates — non-adjacent duplicates would be missed
without the preceding sort.

---

## Behavior

### Input
A sorted list of words, one per line, all lowercase (output of Stage 3: `sort`).

### Output
The same list with consecutive duplicate lines removed. Each unique word appears
exactly once. Order is preserved.

### Examples

```
Input:          Output:
cat             cat
cat             dog
dog             fox
dog             the
fox
the
the
the
```

---

## Implementation

### Backing tool
`uniq`

### Implementation
```bash
uniq
```

### Why not `sort -u`?
Combining sort and deduplication into one step (`sort -u`) would work, but it
would eliminate Stage 3 and Stage 4 as independent, swappable components.
Keeping them separate preserves modularity: either stage can be replaced or
inspected in isolation without touching the other.

---

## File Location
`bin/spell/wp-spell-unique`

Must be executable (`chmod +x`).

---

## Script skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail
uniq
```

---

## Test File
`tests/test-spell-unique.sh`

### Required test cases

| # | Input lines | Expected output lines |
|---|---|---|
| 1 | `cat cat dog` (one per line) | `cat dog` |
| 2 | `the the the` | `the` |
| 3 | no duplicates: `apple berry cat` | `apple berry cat` (unchanged) |
| 4 | single word repeated 100 times | that word once |
| 5 | empty input | no output, exit 0 |

All tests must use `source tests/harness.sh` and call `report` at the end.

---

## Acceptance Criteria
- `bash tests/test-spell-unique.sh` exits 0, all cases PASS
- Script is ≤ 5 lines including shebang and set flags
- Script produces no output to stderr during normal operation
- Output word count is always ≤ input word count
