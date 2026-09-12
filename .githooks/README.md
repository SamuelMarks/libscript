# Git Hooks (`.githooks`)

## Overview

This directory provides custom Git hooks used to maintain code quality, formatting, spelling, and
standards across the repository before commits are recorded.

## Included Hooks

- `pre-commit` (`pre-commit.sh`, `pre-commit.cmd`): Validates modified files prior to commit. It
  runs Prettier formatting, cspell checks, dos2unix normalization, and POSIX shellcheck audits.

## Usage

Configure Git to use this hooks directory locally:

```sh
git config core.hooksPath .githooks
```
