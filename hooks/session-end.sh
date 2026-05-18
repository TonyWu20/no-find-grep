#!/bin/bash
# SessionEnd hook: report blocked-command count and clean up counter file.
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [[ -z "$TRANSCRIPT_PATH" || -z "$SESSION_ID" ]]; then
    exit 0
fi

COUNTER_FILE="$(dirname "$TRANSCRIPT_PATH")/.no-find-grep-blocked-$SESSION_ID"

if [[ -f "$COUNTER_FILE" ]]; then
    COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
    if [[ "$COUNT" -gt 0 ]]; then
        echo "no-find-grep: $COUNT command(s) blocked this session." >&2
    fi
    rm -f "$COUNTER_FILE"
fi

exit 0
