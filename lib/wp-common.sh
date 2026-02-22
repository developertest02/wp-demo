#!/usr/bin/env bash
# lib/wp-common.sh - Shared library for word processing tools
# Source this file in other scripts: source lib/wp-common.sh
# All functions are prefixed with wp_ to avoid namespace collisions
set -uo pipefail

# ANSI color codes for logging
readonly WP_COLOR_GREEN='\033[0;32m'
readonly WP_COLOR_YELLOW='\033[0;33m'
readonly WP_COLOR_RED='\033[0;31m'
readonly WP_COLOR_RESET='\033[0m'

# wp_session_dir - Print the absolute path to the active session directory
# Session dir is $WP_SESSION if set, otherwise ./session
wp_session_dir() {
    if [[ -n "${WP_SESSION:-}" ]]; then
        echo "$WP_SESSION"
    else
        echo "$(pwd)/session"
    fi
}

# wp_current - Print the resolved path of session/current
# Exits with code 1 and message to stderr if session/current does not exist
wp_current() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local current_file="$session_dir/current"
    
    if [[ ! -e "$current_file" ]]; then
        wp_log ERR "No session active: $current_file does not exist"
        exit 1
    fi
    
    # Resolve symlink to get actual path
    readlink -f "$current_file"
}

# wp_commit - Read stdin, write to next numbered snapshot, update current symlink
# Snapshot filenames are zero-padded to 4 digits: 0001.txt, 0002.txt, etc.
# Updates session/current symlink and increments sequence counter in session/meta
wp_commit() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local history_dir="$session_dir/history"
    local meta_file="$session_dir/meta"
    local current_link="$session_dir/current"
    
    # Ensure history directory exists
    mkdir -p "$history_dir"
    
    # Get current sequence number (default to 0 if meta doesn't exist)
    local seq=0
    if [[ -f "$meta_file" ]]; then
        seq=$(grep '^seq=' "$meta_file" | cut -d'=' -f2 | sed 's/^0*//')
        seq=${seq:-0}
    fi
    
    # Increment sequence
    seq=$((seq + 1))
    local padded_seq
    padded_seq=$(printf "%04d" "$seq")
    
    # Write new snapshot
    local snapshot_file="$history_dir/${padded_seq}.txt"
    cat > "$snapshot_file"
    
    # Update current symlink (remove old one first if it exists)
    rm -f "$current_link"
    ln -s "$snapshot_file" "$current_link"
    
    # Update meta file
    local source_file
    if [[ -f "$meta_file" ]]; then
        source_file=$(grep '^source=' "$meta_file" | cut -d'=' -f2-)
    else
        source_file="draft.txt"
    fi
    
    cat > "$meta_file" <<EOF
seq=$padded_seq
source=$source_file
EOF
    
    # Output the snapshot file path for debugging (to stderr)
    wp_log INFO "Committed snapshot $padded_seq"
}

# wp_seq - Print the current sequence number as a plain integer
wp_seq() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local meta_file="$session_dir/meta"
    
    if [[ ! -f "$meta_file" ]]; then
        echo "0"
        return
    fi
    
    local seq
    seq=$(grep '^seq=' "$meta_file" | cut -d'=' -f2 | sed 's/^0*//')
    echo "${seq:-0}"
}

# wp_log - Log a message to stderr with color
# Usage: wp_log LEVEL "message"
# LEVEL is one of: INFO, WARN, ERR
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
            color="$WP_COLOR_RESET"
            ;;
    esac
    
    echo -e "${color}[$level]${WP_COLOR_RESET} $message" >&2
}

# wp_require_cmd - Check that required commands exist
# Usage: wp_require_cmd cmd1 cmd2 ...
# Exits with code 127 if any command is missing
wp_require_cmd() {
    local missing=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        wp_log ERR "Required command(s) not found: ${missing[*]}"
        exit 127
    fi
}

# wp_escape_sed - Escape special characters for use in sed expression
# Usage: wp_escape_sed "some/string.with[special]chars"
# Escapes: / . [ ] * ^ $ \
wp_escape_sed() {
    local input="$1"
    # Escape backslash first, then other special chars
    printf '%s' "$input" | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/\./\\./g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\*/\\*/g' -e 's/\^/\\^/g' -e 's/\$/\\$/g'
}
