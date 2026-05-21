# Changelog

## 1.0.0 — 2026-05-21

### Removed

- **Shell file-read detection:** `sed -n`, `cat -A/-v/-vet`, `xxd`, `od` blocking
  has moved to the new `no-shell-file-ops` plugin.
- **Shell file-edit detection:** `sed -i`, `sd`, `python -c` with `open()` blocking
  has moved to the new `no-shell-file-ops` plugin.
- **PostToolUseFailure hint:** `hint-edit-reread.sh` (Edit stale-string hint)
  has moved to the new `no-shell-file-ops` plugin.

### Fixed

- **SessionEnd counter now surfaces its output:** Changed exit code from 0 to 2
  so stderr is shown as a notice. Added guard against empty counter file values
  to prevent silent `set -e` failures.

### Changed

- **Narrowed scope:** `no-find-grep` now focuses exclusively on find/grep
  substitution enforcement and rg flag misuse detection.
- **Version bump to 1.0.0** to signal the scope contraction. Affected features
  are re-homed in the sibling `no-shell-file-ops` plugin.

## 0.6.1 — 2026-05-18

### Fixed

- **Critical**: Replaced `flock` (Linux-only) with `mkdir`-based portable mutex
  in the blocked-attempts counter (`hooks/block-find-grep.sh`). On macOS,
  `flock` is not available, which caused the entire hook script to crash
  with exit code 127 (instead of reaching `exit 2` to block the command).
  Claude Code treats unknown non-zero exits as hook errors, so all
  blocked-command detection was silently bypassed on macOS.
- Counter failures are now completely non-fatal. If the lock cannot be
  acquired (stale lock, permissions, etc.), the counter silently skips
  the increment rather than risking a hook crash.

## 0.6.0 — 2026-05-18

### Added

- `PostToolUseFailure` hook (`hooks/hint-edit-reread.sh`) that catches Edit tool
  failures when the old_string is not found in the target file (real error:
  `String to replace not found in file.`). Provides `additionalContext` hinting
  the agent to re-read the file with the Read tool before retrying. Limited to
  Edit (not Write) and to "string not found" errors only (not permissions or
  other failures).

## 0.5.0 — 2026-05-18

### Added

- Blocked-attempts counter: displays how many commands were blocked when the
  session exits or `/clear` is run. Counter resets naturally after `/clear`
  since a new session ID is generated.

## 0.4.0 — 2026-05-17

### Added

- Detection for `sed -n` — blocks using sed to view file content instead of the
  Read tool.
- Detection for `cat -A`, `cat -v`, `cat -vet`, `cat -e`, `cat -t` — blocks using
  cat to inspect hidden characters instead of the Read tool.
- Detection for `xxd` — blocks hex dumps of files; use the Read tool.
- Detection for `od` — blocks octal dumps of files; use the Read tool.
- Detection for `sed -i` — blocks in-place file editing with sed; use the Edit tool.
- Detection for `sd` — blocks find-and-replace with sd (which returns exit 0 even on
  no-op); use the Edit tool.
- Detection for `python -c` / `python3 -c` with `open()` — blocks ad-hoc Python
  scripts that read or edit files; use Read/Edit tools.

## 0.3.1 — 2026-05-17

### Added

- Error messages for bare `find` now hint that the command may be installed as
  `fdfind` on Debian/Ubuntu-based Linux distributions.

## 0.3.0 — 2026-05-13

### Fixed

- `-r` flag detection now scopes its check to only the `rg` command's own pipeline
  segment. This eliminates two classes of false positives:
  - **Long flags from other commands:** `cargo --release | rg` no longer falsely
    matches `--release`'s embedded `-re`.
  - **Short flags from other commands:** `fd -rn | rg` no longer falsely matches
    `fd`'s `-rn` flag.

## 0.2.0 — 2026-04-30

### Added

- Detection for `rg -L` (standalone flag) — warns users that `-L` means
  `--follow` in ripgrep, not `--files-without-match` as in GNU grep.
- Detection for `\|` (escaped pipe) in `rg` commands — warns that `\|` matches
  a literal pipe in ripgrep; use bare `|` for alternation.

## 0.1.0 — 2026-04-29

### Added

- Initial release.
- Detection for bare `find` and `grep` commands.
- Detection for `-r<letter>` flags on `rg` commands.
