# Task 07 — `wp-undo` (History & Undo)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 03, 04, 05, 06.
Requires task 00 (Foundation) to be complete before this task begins.

---

## Objective
Implement `bin/wp-undo` — the history navigation tool. It manipulates the
`session/current` symlink and `session/meta` sequence counter to move backward
(or to a specific point) in the document's snapshot history.

`wp-undo` never modifies the content of any snapshot file. It only moves the
pointer that identifies which snapshot is "current."

---

## Interface

```bash
wp-undo [OPTIONS]
```

### Options

| Flag | Description |
|---|---|
| (none) | Step back one snapshot |
| `-n N` | Step back N snapshots |
| `--list` | Print full history with sequence number, timestamp, and word count |
| `--diff N` | Show a colored diff between current snapshot and N steps back |
| `--jump N` | Restore snapshot number N absolutely (ignores current position) |
| `--prune N` | Delete all snapshots older than the most recent N; cannot be undone |

---

## Implementation

### Source the shared library
```bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/wp-common.sh"
```

### Step back (default and `-n`)
1. Read current sequence number via `wp_seq`
2. Compute target: `target = current_seq - N`
3. If `target < 1`: print error "Already at oldest snapshot", exit 1
4. Update `session/current` symlink: `ln -sfn history/$(printf '%04d' $target).txt session/current`
5. Update `seq=` in `session/meta` to the target value

### `--list`
For each file in `session/history/` in ascending order:
```
  [0001]  2024-11-01 14:22:03  312 words   ← current
  [0002]  2024-11-01 14:35:17  289 words
  [0003]  2024-11-01 15:01:44  301 words   ← current
```
- Use `stat --format='%y'` to get modification time
- Use `wc -w` for word count
- Mark the current snapshot with `← current`
- Use `awk` or `printf` for column alignment

### `--diff N`
1. Identify current snapshot path and target snapshot path (N steps back)
2. Run: `diff --color=always <(cat target_snapshot) <(cat current_snapshot)`
3. If `delta` is available (`command -v delta`), pipe through `delta` instead
4. Exit with diff's exit code (1 = differences found, 0 = identical)

### `--jump N`
1. Validate that `session/history/$(printf '%04d' N).txt` exists
2. Update symlink and meta to point to N directly
3. Print confirmation: `Restored snapshot 0003`

### `--prune N`
1. Find all snapshots with sequence number < (current_max - N)
2. Confirm with the user: `About to delete X snapshots. Continue? [y/N]`
3. Delete the files
4. Do not renumber remaining snapshots

---

## File Location
`bin/wp-undo` (executable)

---

## Edge Cases
- Step back when already at snapshot 1: error message, exit 1, session unchanged
- `--jump` to a non-existent snapshot number: error message, exit 1
- `--diff` when only one snapshot exists: "Nothing to diff", exit 0
- `--prune` with N ≥ total snapshot count: "Nothing to prune", exit 0
- `--prune` without user confirmation (answered 'N'): exit 0, nothing deleted

---

## Test File
`tests/test-undo.sh`

### Required test cases

| # | Description | Expected behavior |
|---|---|---|
| 1 | Step back once from snapshot 3 | `wp_seq` becomes 2 |
| 2 | Step back `-n 2` from snapshot 4 | `wp_seq` becomes 2 |
| 3 | Step back from snapshot 1 | Exit 1, error message, seq unchanged |
| 4 | `--list` shows all snapshots | Output contains sequence numbers and word counts |
| 5 | `--jump 2` from snapshot 4 | `wp_seq` becomes 2 |
| 6 | `--jump` to non-existent snapshot | Exit 1, session unchanged |
| 7 | `--diff 1` between two known snapshots | Output contains diff markers |

All tests must set up a temp session with multiple known snapshots, then clean up.
All tests must use `source tests/harness.sh` and call `report` at the end.

---

## Acceptance Criteria
- `bash tests/test-undo.sh` exits 0, all cases PASS
- `wp-undo` never modifies the content of any snapshot file
- `session/current` always resolves to a real, existing file after any operation
- `--list` output is readable in an 80-column terminal
