#!/usr/bin/env bash
# wp-common.sh - Shared library for wp tools
# All functions are prefixed with wp_

# ANSI color codes
readonly WP_COLOR_GREEN='\033[0;32m'
readonly WP_COLOR_YELLOW='\033[0;33m'
readonly WP_COLOR_RED='\033[0;31m'
readonly WP_COLOR_RESET='\033[0m'

# wp_session_dir
# Prints the absolute path to the active session directory
# Uses $WP_SESSION if set, otherwise ./session relative to script location
wp_session_dir() {
    if [[ -n "${WP_SESSION:-}" ]]; then
        # Resolve to absolute path
        cd "$WP_SESSION" 2>/dev/null && pwd || echo "$WP_SESSION"
    else
        # Get the directory where this library is located, then resolve ../session
        local lib_dir
        lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        echo "$lib_dir/../session"
    fi
}

# wp_current
# Prints the resolved path of session/current (the active snapshot file)
# Exits with code 1 and message to stderr if session/current does not exist
wp_current() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local current_link="$session_dir/current"
    
    if [[ ! -e "$current_link" && ! -L "$current_link" ]]; then
        echo "Error: No active session. Run 'wp init' first." >&2
        return 1
    fi
    
    # Resolve the symlink to get the actual file path
    if [[ -L "$current_link" ]]; then
        local target
        target="$(readlink -f "$current_link")"
        echo "$target"
    else
        echo "$current_link"
    fi
}

# wp_commit
# Reads stdin, writes it to the next numbered snapshot in session/history/
# Updates session/current symlink and increments sequence counter in session/meta
wp_commit() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local history_dir="$session_dir/history"
    local meta_file="$session_dir/meta"
    
    # Ensure history directory exists
    mkdir -p "$history_dir"
    
    # Get current sequence number
    local current_seq=0
    if [[ -f "$meta_file" ]]; then
        current_seq="$(grep '^seq=' "$meta_file" | cut -d'=' -f2)"
        current_seq="${current_seq:-0}"
        # Remove leading zeros for arithmetic
        current_seq=$((10#$current_seq))
    fi
    
    # Increment sequence
    local new_seq=$((current_seq + 1))
    local padded_seq
    padded_seq="$(printf '%04d' "$new_seq")"
    
    # Write stdin to new snapshot file
    local snapshot_file="$history_dir/${padded_seq}.txt"
    cat > "$snapshot_file"
    
    # Update or create session/current symlink
    ln -sfn "$snapshot_file" "$session_dir/current"
    
    # Update meta file - preserve other keys, update seq
    local source_file=""
    if [[ -f "$meta_file" ]]; then
        source_file="$(grep '^source=' "$meta_file" | cut -d'=' -f2-)"
    fi
    
    # Write updated meta
    {
        echo "seq=$new_seq"
        if [[ -n "$source_file" ]]; then
            echo "source=$source_file"
        fi
    } > "$meta_file"
    
    echo "$new_seq"
}

# wp_seq
# Prints the current sequence number as a plain integer
wp_seq() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local meta_file="$session_dir/meta"
    
    if [[ ! -f "$meta_file" ]]; then
        echo "0"
        return
    fi
    
    local seq
    seq="$(grep '^seq=' "$meta_file" | cut -d'=' -f2)"
    seq="${seq:-0}"
    # Remove leading zeros
    echo "$((10#$seq))"
}

# wp_log
# Usage: wp_log LEVEL "message"
# LEVEL is one of: INFO, WARN, ERR
# Writes to stderr only, colorized using ANSI codes
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

# wp_require_cmd
# Usage: wp_require_cmd cmd1 cmd2 ...
# Checks that each command exists via `command -v`
# If any are missing, prints an ERR log and exits with code 127
wp_require_cmd() {
    local missing=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        wp_log ERR "Missing required command(s): ${missing[*]}"
        return 127
    fi
    
    return 0
}

# wp_escape_sed
# Usage: wp_escape_sed "some/string.with[special]chars"
# Prints the string with special characters escaped for use in sed
wp_escape_sed() {
    local str="$1"
    # Escape: \ / . [ ] * ^ $
    str="${str//\\/\\\\}"
    str="${str//\//\\/}"
    str="${str//./\\.}"
    str="${str//\[/\\[}"
    str="${str//\]/\\]}"
    str="${str//\*/\\*}"
    str="${str//\^/\\^}"
    str="${str//\$/\\$}"
    echo "$str"
}
