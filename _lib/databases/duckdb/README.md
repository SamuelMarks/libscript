# DuckDB Component

## Overview

This component manages the installation and execution of `duckdb` within the libscript
ecolibscript_native. It provides CLI wrappers to execute SQL queries or start an interactive REPL,
essential for evaluating Execution Accuracy (EX) in Text-to-SQL tasks.

## Usage

Refer to the component's setup and cli scripts for specific operations.

```bash
# Start an interactive REPL
./_lib/databases/duckdb/cli.sh repl my_dataset.duckdb

# Execute a query directly
./_lib/databases/duckdb/cli.sh execute my_dataset.duckdb "SELECT * FROM pretrain_data LIMIT 5;"
```

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.
Libscript manages duckdb versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/duckdb/<version>`.

## Configuration

| Variable                | Description                                                                                                                                                            | Default            | Required |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `DUCKDB_INSTALL_METHOD` | How to install DUCKDB. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DUCKDB_INSTALL_METHOD` | How to install DUCKDB. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `DUCKDB_DOWNLOAD_URL`   | Override URL for downloading duckdb binary or archive artifacts.                                                                                                       | `none`             |                  |
| `DUCKDB_RELEASES_URL`   | Override URL for querying duckdb available remote releases.                                                                                                            | `none`             |                  |
| `DUCKDB_VERSION`        | Specific version of duckdb to install (e.g., latest, lts, or exact version).                                                                                           | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
