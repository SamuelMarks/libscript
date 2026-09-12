# Developer Tools (`devtools`)

## Overview

This directory contains developer tooling, build scripts, auditing utilities, and continuous
integration helpers for developing and maintaining LibScript.

## Subdirectories and Scripts

- **`audit/`**: Stack and component auditing utilities.
- **`ci/`**: Continuous integration test runners and pre-commit automation (`precommit_dance.sh`,
  `precommit_dance.cmd`).
- **`docs-gen/`**: Markdown and marker injection tools for automated documentation generation.
- **`generate_html_docs.sh` / `.cmd`**: Static HTML documentation site generator from Markdown
  sources.

## Usage

Run the CI pre-commit dance locally:

```sh
./devtools/ci/precommit_dance.sh
```
