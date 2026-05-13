# Changelog

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
