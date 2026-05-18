#!/bin/bash
# PostToolUseFailure hook: when Edit fails with "String to replace not found",
# hint the agent to re-read the file before retrying.
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Defense-in-depth: only handle Edit failures (hooks.json matcher also filters).
if [[ "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

ERROR=$(echo "$INPUT" | jq -r '.error // empty')
if [[ -z "$ERROR" ]]; then
    exit 0
fi

# Match known Edit failure: "String to replace not found in file."
if ! echo "$ERROR" | rg -qi 'old_string|string to replace not found'; then
    exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -n "$FILE_PATH" ]]; then
    MESSAGE="The Edit tool failed because the old_string was not found in the file. This usually means the file content has changed since your last read. Re-read \"$FILE_PATH\" with the Read tool, then retry the Edit."
else
    MESSAGE="The Edit tool failed because the old_string was not found in the file. This usually means the file content has changed since your last read. Re-read the target file with the Read tool, then retry the Edit."
fi

jq -n --arg context "$MESSAGE" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUseFailure",
    additionalContext: $context
  }
}'
