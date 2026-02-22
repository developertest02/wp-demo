#!/usr/bin/env bash
# wp-common.sh - Shared library for Word Processor tool
# Source this file in other scripts: source lib/wp-common.sh
# All functions are prefixed with wp_ to avoid namespace collisions

# Prevent multiple sourcing
if [[ -n "${_WP_COMMON_LOADED:-}" ]]; then
    return 0
fi
readonly _WP_COMMON_LOADED=1

# ANSI color codes for logging
readonly WP_COLOR_GREEN='\033[0;32m'
readonly WP_COLOR_YELLOW='\033[0;33m'
readonly WP_COLOR_RED='\033[0;31m'
readonly WP_COLOR_NC='\033[0m'  # No Color

# wp_session_dir
# Prints the absolute path to the active session directory.
# Uses $WP_SESSION if set, otherwise defaults to ./session
# Does not create the directory.
wp_session_dir() {
    local dir="${WP_SESSION:-./session}"
    # Convert to absolute path
    if [[ -d "$dir" ]]; then
        (cd "$dir" && pwd)
    else
        # Directory doesn't exist yet, resolve relative path anyway
        local base_dir="$(dirname "$dir")"
        local base_name="$(basename "$dir")"
        if [[ -d "$base_dir" ]]; then
            echo "$(cd "$base_dir" && pwd)/$base_name"
        else
            # Return as-is if we can't resolve
            echo "$dir"
        fi
    fi
}

# wp_current
# Prints the resolved path of session/current (the active snapshot file).
# Exits with code 1 and error message to stderr if session/current does not exist.
wp_current() {
    local session_dir="$(wp_session_dir)"
    local current_path="$session_dir/current"
    
    if [[ ! -e "$current_path" ]]; then
        echo "Error: No current snapshot found. Run 'wp init <file>' first." >&2
        exit 1
    fi
    
    # Resolve symlink to absolute path
    if [[ -L "$current_path" ]]; then
        local target="$(readlink "$current_path")"
        if [[ ! "$target" = /* ]]; then
            # Relative symlink, resolve relative to session dir
            echo "$session_dir/$target"
        else
            echo "$target"
        fi
    else
        echo "$current_path"
    fi
}

# wp_commit
# Reads stdin, writes it to the next numbered snapshot in session/history/.
# Snapshot filenames are zero-padded to 4 digits: 0001.txt, 0002.txt, etc.
# Updates session/current symlink to point to the new snapshot.
# Increments the sequence counter stored in session/meta.
# session/meta format (plain text, one key=value per line):
#   seq=0003
#   source=draft.txt
wp_commit() {
    local session_dir="$(wp_session_dir)"
    local meta_file="$session_dir/meta"
    
    # Get current sequence number
    local current_seq="0000"
    if [[ -f "$meta_file" ]]; then
        current_seq="$(grep '^seq=' "$meta_file" | cut -d'=' -f2)"
    fi
    
    # Increment sequence (remove leading zeros for arithmetic)
    local seq_num=$((10#$current_seq + 1))
    local new_seq="$(printf '%04d' "$seq_num")"
    
    # Create history directory if needed
    mkdir -p "$session_dir/history"
    
    # Write new snapshot
    local snapshot_file="$session_dir/history/${new_seq}.txt"
    cat > "$snapshot_file"
    
    # Update current symlink
    ln -sf "history/${new_seq}.txt" "$session_dir/current"
    
    # Update meta file (preserve source, update seq)
    local source_file=""
    if [[ -f "$meta_file" ]]; then
        source_file="$(grep '^source=' "$meta_file" | cut -d'=' -f2-)"
    fi
    
    if [[ -z "$source_file" ]]; then
        source_file="unknown"
    fi
    
    cat > "$meta_file" <<EOF
seq=$new_seq
source=$source_file
EOF
}

# wp_seq
# Prints the current sequence number as a plain integer (e.g. 3).
wp_seq() {
    local session_dir="$(wp_session_dir)"
    local meta_file="$session_dir/meta"
    
    if [[ ! -f "$meta_file" ]]; then
        echo "0"
        return
    fi
    
    local seq="$(grep '^seq=' "$meta_file" | cut -d'=' -f2)"
    # Remove leading zeros by treating as base-10 number
    echo "$((10#$seq))"
}

# wp_log
# Usage: wp_log LEVEL "message"
# LEVEL is one of: INFO, WARN, ERR
# Writes to stderr only, never stdout.
# Colorizes output using ANSI codes: INFO=green, WARN=yellow, ERR=red
# Format: [LEVEL] message
wp_log() {
    local level="$1"
    local message="$2"
    local color=""
    
    case "$level" in
        INFO)
            color="$WP_COLOR_GREEN"
            ;;
        WARN)
            color="$WP_COLOR_YELLOW"
            ;;
        ERR)
            color="$WP_COLOR_RED"
            ;;
        *)
            color="$WP_COLOR_NC"
            ;;
    esac
    
    echo -e "${color}[$level] $message${WP_COLOR_NC}" >&2
}

# wp_require_cmd
# Usage: wp_require_cmd cmd1 cmd2 ...
# For each argument, checks that the command exists via `command -v`.
# If any are missing, prints an ERR log and exits with code 127.
wp_require_cmd() {
    local missing=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        wp_log ERR "Missing required command(s): ${missing[*]}"
        exit 127
    fi
}

# wp_escape_sed
# Usage: wp_escape_sed "some/string.with[special]chars"
# Prints the string with /, ., [, ], *, ^, $, \ escaped for use in a sed expression.
wp_escape_sed() {
    local str="$1"
    # Escape special sed characters: \ [ ] / . * ^ $
    printf '%s' "$str" | sed -e 's/[]\/$*.^[]/\\&/g'
}
