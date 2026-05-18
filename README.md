# no-find-grep

A [Claude Code](https://claude.ai/code) plugin that blocks agents from using shell commands to read or edit files — enforcing the built-in `Read` and `Edit` tools. Also blocks bare `find`/`grep` and detects common `rg` misuse.

## What it does

Registers a `PreToolUse` hook that intercepts every Bash command before execution. It detects and blocks:

| Pattern | Why | Example |
|---------|-----|---------|
| Bare `find` | Use `fd` (or `fdfind` on Debian/Ubuntu) instead | `find . -name '*.txt'` |
| Bare `grep` | Use `rg` instead | `grep -rn 'pattern' .` |
| `rg` with `-r<letter>` (scoped to rg's own flags) | `-r` means `--replace` in rg, not `--recursive`. The letter becomes replacement text. rg is recursive by default. Only flags on the `rg` command itself are checked — other commands' `-r` flags in a pipeline are ignored. | `rg -rn 'pattern' .` → replaces matches with "n" |
| `rg` with standalone `-L` | `-L` means `--follow` in rg, not `--files-without-match` in grep | `rg -L 'pattern' .` |
| `rg` with `\|` | rg uses `|` for alternation, `\|` matches a literal pipe | `rg 'foo\|bar'` → matches `foo|bar` literal |
| `sed -n` | Use `Read` tool to view file content instead of parsing with sed | `sed -n '100,200p' file` |
| `cat -A/-v/-vet` | Use `Read` tool to inspect file content instead of shell tricks | `cat -A file` |
| `xxd` / `od` | Use `Read` tool to inspect file content instead of hex/octal dumps | `xxd file` |
| `sed -i` | Use `Edit` tool for file editing instead of sed in-place | `sed -i 's/old/new/' file` |
| `sd` | Use `Edit` tool for find-and-replace. sd always returns exit 0 even on no-op. | `sd 'old' 'new' file` |
| `python -c` with `open()` | Use `Read`/`Edit` tools for file operations instead of ad-hoc scripts | `python3 -c "open('f').read()"` |
| `Edit` tool `PostToolUseFailure` | When `Edit` fails with `String to replace not found`, hints agent to re-read the file with `Read` tool before retrying | Agent context covers all `PostToolUseFailure` events |

When a match is found, the hook prints a diagnostic message to stderr and exits with code 2, preventing the command from running.

## Why CLAUDE.md wasn't enough

My global CLAUDE.md already says:

> Always use `fd` and `rg` over `find` and `grep`. For file editing, use the built-in `Edit` tool instead of `sed -i`, `sd`, or `python -c`.

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
| `hooks/block-find-grep.sh` | Shell script that blocks `find`/`grep` misuse, `rg` misuse, and shell-based file read/edit (enforcing `Read`/`Edit` tools) |
| `hooks/hint-edit-reread.sh` | Shell script that catches `Edit` tool failures and hints the agent to re-read the file via `additionalContext` |
| `hooks/session-end.sh` | Shell script that reports blocked-command count on session exit and `/clear` |

