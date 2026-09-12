# CLI Commands (`cli/commands`)

## Overview

This directory contains modular command implementations dispatched by the LibScript CLI
(`libscript.sh` / `libscript.cmd`).

## Submodules

- **`cloud`**: Cloud infrastructure management commands for AWS, Azure, and GCP.
- **`core`**: Core utilities including semantic versioning and platform resolution.
- **`deps`**: Dependency resolution and JSON manifest parsing.
- **`packaging`**: Multi-format packaging and installer generation logic.
- **`registry`**: Component search and SQLite database indexing.
- **`services`**: Service management actions (start, stop, status, healthcheck).

## Usage

Commands in this directory are invoked through the main CLI entry point:

```sh
./libscript.sh [command] [args...]
```
