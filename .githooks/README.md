# Git Hooks (`.githooks`)

## Overview

This directory provides custom Git hooks used to maintain code quality, formatting, spelling, and
standards across the repository before commits are recorded.

## Included Hooks

- `pre-commit` (`pre-commit.sh`, `pre-commit.cmd`): Validates modified files prior to commit. It
  runs Prettier formatting, cspell checks, dos2unix/unix2dos normalization, LibScript engineering
  standards & POSIX audits, automatic `shellcheck` bootstrapping via `_lib/toolchains/shellcheck`
  (installing `shellcheck` idempotently into `${LIBSCRIPT_HOME}/shellcheck` when nonexistent on
  `PATH`) followed by POSIX `shellcheck -s sh` static analysis, component README regeneration, and
  updates the `% doc coverage` shield in `README.md`.

## Usage

Configure Git to use this hooks directory locally:

```sh
git config core.hooksPath .githooks
```
