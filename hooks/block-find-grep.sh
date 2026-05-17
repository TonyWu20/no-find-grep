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
	exit 2
fi

# Detect sed -n (viewing file lines instead of using Read tool).
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)sed(\s|$)' && echo "$COMMAND" | rg -o '(^|[|;&$()]+\s*)sed[^|;&$()]*' | rg -q '(\s|^)-[a-zA-Z]*n[a-zA-Z]*'; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  sed -n DETECTED! Use the Read tool to view file content!" >&2
	echo "  sed -n is for peeking at files. Read tool does this better." >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: Use the Read tool with offset/limit to view specific lines" >&2
	echo "============================================================" >&2
	exit 2
fi

# Detect cat -A/-v/-vet/-e/-t/-E/-T (inspecting hidden chars instead of Read tool).
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)cat(\s|$)' && echo "$COMMAND" | rg -o '(^|[|;&$()]+\s*)cat[^|;&$()]*' | rg -q '(\s|^)-[a-zA-Z]*[AvVeEtT][a-zA-Z]*'; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  cat WITH INSPECTION FLAGS DETECTED!" >&2
	echo "  Use the Read tool to inspect file content instead of cat -A/-v/-vet!" >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: Use the Read tool to view the file" >&2
	echo "============================================================" >&2
	exit 2
fi

# Detect xxd (hex dump instead of Read tool).
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)xxd(\s|$)'; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  xxd DETECTED! Use the Read tool to inspect file content!" >&2
	echo "  xxd is for hex dumps. Read tool shows file contents directly." >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: Use the Read tool instead of xxd" >&2
	echo "============================================================" >&2
	exit 2
fi

# Detect od (octal dump instead of Read tool).
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)od(\s|$)'; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  od DETECTED! Use the Read tool to inspect file content!" >&2
	echo "  od is for octal/hex dumps. Read tool shows file contents directly." >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: Use the Read tool instead of od" >&2
	echo "============================================================" >&2
	exit 2
fi

# Detect sed -i (in-place editing instead of Edit tool).
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)sed(\s|$)' && echo "$COMMAND" | rg -o '(^|[|;&$()]+\s*)sed[^|;&$()]*' | rg -q '(\s|^)-[a-zA-Z]*i[a-zA-Z]*'; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  sed -i DETECTED! Use the Edit tool for file editing!" >&2
	echo "  sed -i is for in-place file editing. Edit tool does this better." >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: Use the Edit tool to modify the file" >&2
	echo "============================================================" >&2
	exit 2
fi

# Detect sd (find-and-replace instead of Edit tool).
# sd returns exit code 0 even when no substitution occurs, so agents
# cannot rely on it for success/failure detection.
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)sd(\s|$)'; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  sd DETECTED! Use the Edit tool for file find-and-replace!" >&2
	echo "  sd always returns exit code 0 even when no substitution happens." >&2
	echo "  Edit tool is the correct way to edit files, not sd." >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: Use the Edit tool to modify the file" >&2
	echo "============================================================" >&2
	exit 2
fi

# Detect python -c/python3 -c with file operations (open()) instead of Read/Edit.
if echo "$COMMAND" | rg -q '(^|[|;&$()]+\s*)python3?(\s|$)' && echo "$COMMAND" | rg -q '\s-c\s' && echo "$COMMAND" | rg -q 'open\('; then
	TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	echo "============================================================" >&2
	echo "  python -c WITH FILE OPERATIONS DETECTED!" >&2
	echo "  Use the Read or Edit tool instead of ad-hoc Python scripts!" >&2
	echo "  Your command: $COMMAND" >&2
	echo "  Fix: Use Read tool to read files, Edit tool to modify them" >&2
	echo "============================================================" >&2
	exit 2
fi

exit 0
