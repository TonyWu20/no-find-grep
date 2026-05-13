# no-find-grep

A [Claude Code](https://claude.ai/code) plugin that blocks bare `find` and `grep` commands in Bash tool calls, and detects common `rg` misuse (like `\|` for alternation, `-r` for recursive). Tells you to use `fd` and `rg` correctly instead.

## What it does

Registers a `PreToolUse` hook that intercepts every Bash command before execution. It detects and blocks:

| Pattern | Why | Example |
|---------|-----|---------|
| Bare `find` | Use `fd` instead | `find . -name '*.txt'` |
| Bare `grep` | Use `rg` instead | `grep -rn 'pattern' .` |
| `rg` with `-r<letter>` (scoped to rg's own flags) | `-r` means `--replace` in rg, not `--recursive`. The letter becomes replacement text. rg is recursive by default. Only flags on the `rg` command itself are checked — other commands' `-r` flags in a pipeline are ignored. | `rg -rn 'pattern' .` → replaces matches with "n" |
| `rg` with standalone `-L` | `-L` means `--follow` in rg, not `--files-without-match` in grep | `rg -L 'pattern' .` |
| `rg` with `\|` | rg uses `|` for alternation, `\|` matches a literal pipe | `rg 'foo\|bar'` → matches `foo|bar` literal |

When a match is found, the hook prints a diagnostic message to stderr and exits with code 2, preventing the command from running.

## Why CLAUDE.md wasn't enough

My global CLAUDE.md already says:

> Always use `fd`, `rg` and `sd` over `find`, `grep` and `sed`.

But Claude Code doesn't always read or follow instructions consistently — it falls back to `find`/`grep` out of habit, and often uses grep flags with `rg`. A hook enforces the rule at the tool level, every time, with no exceptions. There's no "I didn't read the instructions" loophole.

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

