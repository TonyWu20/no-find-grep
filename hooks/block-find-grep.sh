#!/bin/bash
# PreToolUse hook: block bare find/grep in Bash tool calls.
# Project CLAUDE.md requires: ALWAYS use fd/rg over find/grep.
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
	exit 0
fi

# Block bare find/grep commands (not fd/rg).
# Catch: "^find ", "^grep ", "| find ", "| grep ", "; find ", etc.
# Allow: fd, rg, git grep, etc.

if echo "$COMMAND" | grep -qE '(^|[|;&$()]+\s*)find(\s|$)'; then
	# Don't block if "fd" is being used instead
	# (check: 'find' is NOT part of 'fd')

	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  BARE find DETECTED! Use fd instead of find!" >&2
	echo "  READ YOUR DAMN CLAUDE.md: fd, NOT find!" >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: replace 'find' with 'fd'" >&2
	echo "============================================================" >&2
	exit 2
fi

if echo "$COMMAND" | grep -qE '(^|[|;&$()]+\s*)grep(\s|$)'; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  BARE grep DETECTED! Use rg instead of grep!" >&2
	echo "  READ YOUR DAMN CLAUDE.md: rg, NOT grep!" >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: replace 'grep' with 'rg'" >&2
	echo "============================================================" >&2
	exit 2
fi

exit 0
