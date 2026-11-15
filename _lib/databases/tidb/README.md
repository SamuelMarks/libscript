# tidb

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `tidb` component (part of
`_databases`) within the LibScript ecosystem. Open-source distributed Hybrid Transactional and
Analytical Processing (HTAP) SQL database compatible with MySQL.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **TiDB**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install tidb
libscript uninstall tidb
```

**Start / Stop (if configured as a background service):**

```sh
libscript start tidb
libscript stop tidb
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker tidb
```

_Note: On Unix environments, you can also use `./cli.sh install tidb`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TIDB_INSTALL_METHOD` | How to install tidb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TIDB_VERSION`        | Specific version of tidb to install.                                                                                                          | `latest`           | latest, lts      |
| `TIDB_DOWNLOAD_URL`   | Override URL for downloading tidb binary or archive artifacts.                                                                                | `none`             |                  |
| `TIDB_RELEASES_URL`   | Override URL for querying tidb available remote releases.                                                                                     | `none`             |                  |
| `TIDB_LISTEN_PORT`    | TCP port on which the tidb service listens.                                                                                                   | `4000`             |                  |

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
