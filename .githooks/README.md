# Repository Git Hooks (`.githooks/`)

## Overview

`.githooks/` provides cross-platform (`pre-commit`, `pre-commit.sh`, `pre-commit.cmd`) Git
pre-commit hooks enforcing spellcheck (`cspell`), engineering standards (`audit_standards`),
`T0`–`T5` tier boundaries (`audit_tiers`), 100% documentation coverage (`doc_coverage`),
schema-driven Markdown regeneration (`generate_markdown_docs`), and `prettier` formatting before
commits are recorded.

## Installation

```sh
git config core.hooksPath .githooks
```
