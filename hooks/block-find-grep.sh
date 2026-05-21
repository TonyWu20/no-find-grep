#!/bin/bash
# PreToolUse hook: block bare find/grep in Bash tool calls.
# Project CLAUDE.md requires: ALWAYS use fd/rg over find/grep.
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

COUNTER_FILE=""
if [[ -n "$TRANSCRIPT_PATH" && -n "$SESSION_ID" ]]; then
    COUNTER_FILE="$(dirname "$TRANSCRIPT_PATH")/.no-find-grep-blocked-$SESSION_ID"
fi

increment_counter() {
    if [[ -z "$COUNTER_FILE" ]]; then
        return
    fi

    local lockdir="${COUNTER_FILE}.lock"
    local retries=0

    until mkdir "$lockdir" 2>/dev/null; do
        retries=$((retries + 1))
        if [[ $retries -ge 10 ]]; then
            return
        fi
        sleep 0.01 || return
    done

    local count=0
    if [[ -f "$COUNTER_FILE" ]]; then
        count=$(cat "$COUNTER_FILE" 2>/dev/null) || count=0
    fi
    echo $((count + 1)) > "$COUNTER_FILE" 2>/dev/null || true

    rmdir "$lockdir" 2>/dev/null || true
}

if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Block bare find/grep commands (not fd/rg).
# Catch: "^find ", "^grep ", "| find ", "| grep ", "; find ", etc.
# Allow: fd, rg, git grep, etc.

if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)find(\s|$)'; then
    # Don't block if "fd" is being used instead
    # (check: 'find' is NOT part of 'fd')

    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "============================================================" >&2
    echo "  BARE find DETECTED! Use fd (or fdfind on Debian/Ubuntu) instead of find!" >&2
    echo "  READ YOUR DAMN CLAUDE.md: fd (or fdfind), NOT find!" >&2
    echo "  Your command: $COMMAND" >&2
    echo "  Fix: replace 'find' with 'fd' (or 'fdfind' on Debian/Ubuntu)" >&2
    echo "============================================================" >&2
    increment_counter
    exit 2
fi

if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)grep(\s|$)'; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "============================================================" >&2
    echo "  BARE grep DETECTED! Use rg instead of grep!" >&2
    echo "  READ YOUR DAMN CLAUDE.md: rg, NOT grep!" >&2
    echo "  Your command: $COMMAND" >&2
    echo "  Fix: replace 'grep' with 'rg'" >&2
    echo "============================================================" >&2
    increment_counter
    exit 2
fi

# Detect rg commands with -r followed by a letter (NOT space or =).
# GNU grep: -r means --recursive. rg: -r means --replace.
# -rn/-ri/-rl etc. silently consume the letter as replacement text.
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)rg(\s|$)' && echo "$COMMAND" | rg -o '(^|[|;&$()]+\s*)rg[^|;&$()]*' | rg -q '(^|\s)-r[a-zA-Z]'; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "============================================================" >&2
    echo "  grep -r FLAG DETECTED IN rg COMMAND!" >&2
    echo "  In rg, -r means --replace, NOT --recursive like grep." >&2
    echo "  rg is ALREADY recursive by default — no -r flag needed." >&2
    echo "  Your command: $COMMAND" >&2
    echo "  Fix: remove the -r flag. rg searches recursively by default." >&2
    echo "============================================================" >&2
    increment_counter
    exit 2
fi

# Detect rg commands with standalone -L flag.
# GNU grep: -L means --files-without-match. rg: -L means --follow.
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)rg(\s|$)' && echo "$COMMAND" | rg -q '(^|\s)-L(\s|$)'; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "============================================================" >&2
    echo "  grep -L FLAG DETECTED IN rg COMMAND!" >&2
    echo "  In rg, -L means --follow, NOT --files-without-match!" >&2
    echo "  Your command: $COMMAND" >&2
    echo "  Fix: use 'rg --files-without-match' for grep -L behavior" >&2
    echo "============================================================" >&2
    increment_counter
    exit 2
fi

# Detect rg commands with escaped pipe (\|).
# rg uses | for alternation, NOT \|. \| matches a literal pipe char.
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)rg(\s|$)' && echo "$COMMAND" | rg -qF '\|'; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "============================================================" >&2
    echo "  ESCAPED PIPE IN rg DETECTED! \\| means literal pipe in rg!" >&2
    echo "  READ YOUR DAMN CLAUDE.md: rg uses | for alternation, NOT \\|!" >&2
    echo "  Your command: $COMMAND" >&2
    echo "  Fix: replace '\\|' with '|' in your rg pattern" >&2
    echo "============================================================" >&2
    increment_counter
    exit 2
fi

exit 0
