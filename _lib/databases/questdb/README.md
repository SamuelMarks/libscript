# questdb

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `questdb` component (part
of `_databases`) within the LibScript ecosystem. High-throughput open-source time-series database
with fast SQL, InfluxDB Line Protocol, and PostgreSQL wire support.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **QuestDB**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install questdb
libscript uninstall questdb
```

**Start / Stop (if configured as a background service):**

```sh
libscript start questdb
libscript stop questdb
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker questdb
```

_Note: On Unix environments, you can also use `./cli.sh install questdb`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `QUESTDB_INSTALL_METHOD` | How to install questdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `QUESTDB_VERSION`        | Specific version of questdb to install.                                                                                                          | `latest`           | latest, lts      |
| `QUESTDB_DOWNLOAD_URL`   | Override URL for downloading questdb binary or archive artifacts.                                                                                | `none`             |                  |
| `QUESTDB_RELEASES_URL`   | Override URL for querying questdb available remote releases.                                                                                     | `none`             |                  |
| `QUESTDB_LISTEN_PORT`    | TCP port on which the questdb service listens.                                                                                                   | `9000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
