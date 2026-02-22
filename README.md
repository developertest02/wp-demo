# WP Demo — Text Editing Pipeline Tools

## Description

A Unix-style text editing pipeline toolkit built with bash. The project provides a session-based workflow where documents are processed through a series of composable filter tools. The philosophy follows the Unix way: small, focused tools that do one thing well and can be chained together via pipes. The session layer maintains snapshots of your document history, enabling undo/redo functionality and safe experimentation.

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Bash | 4.0+ | Required for all scripts |
| GNU coreutils | any | `cat`, `sed`, `sort`, `uniq`, `comm`, `diff` |
| POSIX shell | yes | All scripts use `#!/usr/bin/env bash` |

## Quick Start

```bash
# 1. Initialize a session with your document
wp init myfile.txt

# 2. Check spelling (after installation, wp-spell is available in PATH)
wp pipe | wp-spell

# 3. Fix a misspelling
wp run wp-search "kittne" "kitten"

# 4. View document statistics
wp pipe | wp-stats -w

# 5. Undo if needed
wp-undo

# 6. Save when done
wp save
```

## Tools

### `wp` — Main Dispatcher

The central command for session management.

| Subcommand | Description |
|---|---|
| `init <file>` | Initialize a new session with the given file |
| `save [outfile]` | Save current snapshot to outfile (or original source) |
| `run <script> [args]` | Pipe current snapshot through `bin/<script>` |
| `pipe` | Cat current snapshot to stdout |
| `status` | Show session status (source, snapshot number, word count) |
| `clean` | Remove the session directory |

### `wp-search` — Search and Replace

Performs search and replace on document text.

```bash
wp-search [OPTIONS] PATTERN REPLACEMENT
```

| Option | Description |
|---|---|
| `-i` | Case-insensitive matching |
| `-n N` | Replace only the Nth occurrence |
| `-r` | Pattern is an extended regular expression |
| `-p` | Preview mode: show diff without committing |

### `wp-stats` — Document Statistics

Displays statistics about the current document.

```bash
wp-stats [OPTIONS]
```

| Option | Description |
|---|---|
| `-w` | Word count only |
| `-l` | Line count only |
| `-c` | Character count only |

### `wp-undo` — Undo Last Change

Reverts to the previous snapshot in the session history.

```bash
wp-undo
```

Decrements the sequence number and updates the `current` symlink to point to the previous snapshot.

### `wp-spell` — Spell Check Pipeline

Runs the full spell-check pipeline and outputs misspelled words.

```bash
wp-spell [OPTIONS] [FILE]
```

| Option | Description |
|---|---|
| `-d FILE` | Use an alternate dictionary file |
| `-a WORD` | Add WORD to the dictionary, then exit |
| `--count` | Print only the count of misspelled words |
| `--no-commit` | Force read-only mode (no effect, never commits) |

If no FILE is provided, reads from the current session.

#### Spell Pipeline Stages

The spell checker is composed of five stages:

1. **wp-spell-words** — Extract words from text (one per line)
2. **wp-spell-lower** — Convert to lowercase
3. **sort** — Sort words alphabetically
4. **wp-spell-unique** — Remove duplicates
5. **wp-spell-mismatch** — Compare against dictionary

## Dictionary Maintenance

The dictionary file (`lib/dictionary.txt`) contains correctly spelled words, one per line, in lowercase and sorted alphabetically.

### Adding a Word

Use the `-a` flag to add a word:

```bash
wp-spell -a "newword"
```

This appends the word (converted to lowercase) and re-sorts the dictionary.

### Manual Editing

To manually edit the dictionary:

```bash
# Edit the dictionary
vim lib/dictionary.txt

# Re-sort after editing
sort -o lib/dictionary.txt lib/dictionary.txt
```

### Dictionary Format

- One word per line
- All lowercase
- Sorted alphabetically
- No duplicates

## Running Tests

### Run All Tests

```bash
make test
```

Or manually:

```bash
for t in tests/test-*.sh; do bash "$t"; done
```

### Individual Test Files

```bash
bash tests/test-foundation.sh
bash tests/test-spell-integration.sh
bash tests/test-e2e.sh
```

### Test Harness

All tests use `tests/harness.sh` which provides:

- `assert_eq DESCRIPTION EXPECTED ACTUAL`
- `assert_contains DESCRIPTION HAYSTACK NEEDLE`
- `assert_not_contains DESCRIPTION HAYSTACK NEEDLE`
- `assert_exit_code DESCRIPTION EXPECTED ACTUAL`
- `report` — Print summary and exit with appropriate code

## Installation

```bash
make install
```

Installs scripts to `~/.local/bin` and data files to `~/.local/share/wp-demo/` by default.

| Variable | Default | Description |
|---|---|---|
| `INSTALL_DIR` | `~/.local/bin` | Where to install executable scripts |
| `INSTALL_DATA_DIR` | `~/.local/share/wp-demo` | Where to install data files and spell scripts |

To override:

```bash
make install INSTALL_DIR=/usr/local/bin INSTALL_DATA_DIR=/usr/local/share/wp-demo
```

After installation, ensure `~/.local/bin` is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Uninstall

```bash
make uninstall
```

## Project Structure

Source repository layout:

```
wp-demo/
├── bin/
│   ├── wp              # Main dispatcher
│   ├── wp-search       # Search and replace
│   ├── wp-stats        # Document statistics
│   ├── wp-undo         # Undo last change
│   └── spell/
│       ├── wp-spell          # Spell pipeline assembler
│       ├── wp-spell-words    # Extract words
│       ├── wp-spell-lower    # Convert to lowercase
│       ├── wp-spell-unique   # Remove duplicates
│       └── wp-spell-mismatch # Compare against dictionary
├── lib/
│   ├── wp-common.sh    # Shared library
│   ├── dictionary.txt  # Spell check dictionary
│   └── stopwords.txt   # Common words list
├── tests/
│   ├── harness.sh      # Test framework
│   ├── test-*.sh       # Test scripts
│   └── fixtures/       # Test fixtures
├── Makefile
└── README.md
```

After `make install`:

```
~/.local/bin/
├── wp              # Main dispatcher
├── wp-search       # Search and replace
├── wp-stats        # Document statistics
├── wp-undo         # Undo last change
└── wp-spell        # Wrapper script for spell checker

~/.local/share/wp-demo/
├── bin/spell/
│   ├── wp-spell          # Spell pipeline assembler
│   ├── wp-spell-words    # Extract words
│   ├── wp-spell-lower    # Convert to lowercase
│   ├── wp-spell-unique   # Remove duplicates
│   └── wp-spell-mismatch # Compare against dictionary
└── lib/
    ├── wp-common.sh    # Shared library
    ├── dictionary.txt  # Spell check dictionary
    └── stopwords.txt   # Common words list
```

## Session Structure

When you run `wp init`, the following structure is created:

```
session/
├── current -> history/0001.txt   # Symlink to current snapshot
├── history/
│   ├── 0001.txt                  # First snapshot
│   ├── 0002.txt                  # Second snapshot
│   └── ...
└── meta                          # Session metadata (seq, source)
```

## License

MIT
