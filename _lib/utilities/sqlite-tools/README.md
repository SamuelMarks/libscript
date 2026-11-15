# sqlite-tools

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `sqlite-tools` component
(part of `_utilities`) within the LibScript ecosystem. Official SQLite command-line bundle providing
sqlite3 shell, sqldiff, and sqlite3_analyzer.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **SQLite CLI Tools**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install sqlite-tools
libscript uninstall sqlite-tools
```

**Start / Stop (if configured as a background service):**

```sh
libscript start sqlite-tools
libscript stop sqlite-tools
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker sqlite-tools
```

_Note: On Unix environments, you can also use `./cli.sh install sqlite-tools`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                                           | Default            | Aliases/Examples |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SQLITE_TOOLS_INSTALL_METHOD` | How to install sqlite-tools. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SQLITE_TOOLS_VERSION`        | Specific version of sqlite-tools to install.                                                                                                          | `latest`           | latest, lts      |
| `SQLITE_TOOLS_DOWNLOAD_URL`   | Override URL for downloading sqlite-tools binary or archive artifacts.                                                                                | `none`             |                  |
| `SQLITE_TOOLS_RELEASES_URL`   | Override URL for querying sqlite-tools available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
