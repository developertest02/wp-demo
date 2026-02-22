# Task 06 — `wp-search` (Search & Replace Filter)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 03, 04, 05, 07.
Requires task 00 (Foundation) to be complete before this task begins.

---

## Objective
Implement `bin/wp-search` — a mutating filter that performs search and replace
on document text. It reads from stdin, applies a substitution, writes the result
to stdout, and calls `wp_commit` to snapshot the change.

---

## Interface

```bash
wp-search [OPTIONS] PATTERN REPLACEMENT
```

Input is always stdin. Output is always stdout.

### Options

| Flag | Description |
|---|---|
| `-i` | Case-insensitive matching |
| `-g` | Replace all occurrences per line (default behavior) |
| `-n N` | Replace only the Nth occurrence globally |
| `-r` | PATTERN is an extended regular expression (ERE) |
| `-p` | Preview mode: show a colored diff, do not commit |

### Arguments
- `PATTERN` — the text or regex to search for
- `REPLACEMENT` — the text to substitute in

---

## Implementation

### Backing tool
`sed`

### Core substitution
```bash
sed -E "s/${ESCAPED_PATTERN}/${ESCAPED_REPLACEMENT}/g"
```

### Delimiter safety
The `/` character in PATTERN or REPLACEMENT will break the sed expression.
Use `wp_escape_sed` from `lib/wp-common.sh` to escape both arguments before
inserting them into the sed command. Alternatively, use `|` as the sed delimiter:
```bash
sed -E "s|${PATTERN}|${REPLACEMENT}|g"
```
If using `|` as delimiter, still escape `|` characters in the pattern.

### Case-insensitive flag
Append `I` to the sed flags: `s/pattern/replacement/gI`

### Nth occurrence (`-n N`)
sed's occurrence modifier: `s/pattern/replacement/N` where N is an integer.
Note: this replaces only the Nth occurrence on each line, not globally.
Document this limitation in the `--help` output.

### Preview mode (`-p`)
1. Apply the substitution to a temp file (do not modify session)
2. Run `diff --color=always session/current <(tmpfile)` and display it
3. Exit without calling `wp_commit`

### Session integration
Source `lib/wp-common.sh` at the top of the script.
After performing the substitution, pipe the result through `wp_commit`:
```bash
cat "$INPUT" | sed ... | wp_commit
```
In preview mode, skip `wp_commit`.

---

## File Location
`bin/wp-search` (executable)

---

## Error handling
- If PATTERN or REPLACEMENT are not provided: print usage to stderr, exit 1
- If the sed expression fails (malformed regex): print the sed error to stderr, exit with sed's exit code
- If no session is active and no FILE is provided: print a clear message, exit 1

---

## Test File
`tests/test-search.sh`

### Required test cases

| # | Description | Expected behavior |
|---|---|---|
| 1 | Simple literal replace | "cat" → "dog" in known input |
| 2 | Case-insensitive `-i` | "Cat", "CAT", "cat" all replaced |
| 3 | ERE pattern `-r` | Regex `\b(Mr\|Mrs)\.\b` → `Mx.` |
| 4 | `-n 2` flag | Only the 2nd occurrence replaced |
| 5 | Preview mode `-p` | Output contains diff markers, session unchanged |
| 6 | Pattern with `/` character | Does not break sed expression |
| 7 | No match | Input passes through unchanged, exit 0 |
| 8 | Empty input | No output, exit 0 |

All tests must use `source tests/harness.sh` and call `report` at the end.
Tests that call `wp_commit` should initialize a temp session first and clean up after.

---

## Acceptance Criteria
- `bash tests/test-search.sh` exits 0, all cases PASS
- After a non-preview run, `wp_seq` is incremented by 1
- After a preview run, `wp_seq` is unchanged
- Script handles patterns containing `/`, `[`, `]`, `*`, `\` without crashing
