# Repository Git Hooks (`.githooks/`)

## Overview

`.githooks/` provides cross-platform (`pre-commit`, `pre-commit.sh`, `pre-commit.cmd`) Git
pre-commit hooks orchestrating staged formatting (`prettier`), concurrent static checks (`cspell`,
`audit_standards`, `audit_posix`, `audit_tiers`, `audit_version_manager`, `audit_schema_vars`,
`shellcheck`, `wincheck`, and `doc_coverage`), and schema-driven Markdown/README regeneration via
`engine/common/parallel.{sh,cmd}`.

Worker concurrency auto-detects available CPU cores (`hw_tune.{sh,cmd}`), honors explicit
`LIBSCRIPT_JOBS=<N>` overrides, and gracefully falls back to sequential execution
(`LIBSCRIPT_JOBS=1`) on MS-DOS (`IS_MSDOS=1`) or shells without background job support.

## Installation

```sh
git config core.hooksPath .githooks
```
