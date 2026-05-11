# no-find-grep

A [Claude Code](https://claude.ai/code) plugin that blocks bare `find` and `grep` commands in Bash tool calls, and detects common `rg` misuse (like `\|` for alternation). Tells you to use `fd` and `rg` correctly instead.

## What it does

Registers a `PreToolUse` hook that intercepts every Bash command before execution. If the command contains a bare `find` or `grep` (standalone, not part of `fd`/`rg`/`git grep`), or uses `\|` inside an `rg` command (which means literal pipe, not alternation), the hook prints a message and exits with code 2, preventing the command from running.

## Why CLAUDE.md wasn't enough

My global CLAUDE.md already says:

> Always use `fd`, `rg` and `sd` over `find`, `grep` and `sed`.

But Claude Code doesn't always read or follow instructions consistently — it falls back to `find`/`grep` out of habit. A hook enforces the rule at the tool level, every time, with no exceptions. There's no "I didn't read the instructions" loophole.

## Install

Install via the marketplace:

```
TonyWu20/my-claude-marketplace
```

Or manually, register the plugin in your Claude Code settings:

```json
{
  "plugins": {
    "no-find-grep": {
      "path": "/path/to/no-find-grep"
    }
  }
}
```

## Files

| File | Purpose |
|------|---------|
| `hooks/hooks.json` | Hook registration — intercepts `Bash` tool calls |
| `hooks/block-find-grep.sh` | Shell script that checks for `find`/`grep` and `rg` misuse and blocks them |
