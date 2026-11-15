# surrealdb

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `surrealdb` component
(part of `_databases`) within the LibScript ecosystem. Scalable distributed multi-model cloud
database supporting relational, document, graph, and vector queries.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **SurrealDB**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install surrealdb
libscript uninstall surrealdb
```

**Start / Stop (if configured as a background service):**

```sh
libscript start surrealdb
libscript stop surrealdb
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker surrealdb
```

_Note: On Unix environments, you can also use `./cli.sh install surrealdb`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SURREALDB_INSTALL_METHOD` | How to install surrealdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SURREALDB_VERSION`        | Specific version of surrealdb to install.                                                                                                          | `latest`           | latest, lts      |
| `SURREALDB_DOWNLOAD_URL`   | Override URL for downloading surrealdb binary or archive artifacts.                                                                                | `none`             |                  |
| `SURREALDB_RELEASES_URL`   | Override URL for querying surrealdb available remote releases.                                                                                     | `none`             |                  |
| `SURREALDB_LISTEN_PORT`    | TCP port on which the surrealdb service listens.                                                                                                   | `8000`             |                  |

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
