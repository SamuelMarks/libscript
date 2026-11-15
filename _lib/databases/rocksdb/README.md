# rocksdb

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `rocksdb` component (part
of `_databases`) within the LibScript ecosystem. Embeddable persistent LSM-tree key-value store
library and ldb administration CLI tools optimized for fast flash storage.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **RocksDB**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install rocksdb
libscript uninstall rocksdb
```

**Start / Stop (if configured as a background service):**

```sh
libscript start rocksdb
libscript stop rocksdb
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker rocksdb
```

_Note: On Unix environments, you can also use `./cli.sh install rocksdb`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `ROCKSDB_INSTALL_METHOD` | How to install rocksdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `ROCKSDB_VERSION`        | Specific version of rocksdb to install.                                                                                                          | `latest` | latest, lts      |
| `ROCKSDB_DOWNLOAD_URL`   | Override URL for downloading rocksdb binary or archive artifacts.                                                                                | `none`   |                  |
| `ROCKSDB_RELEASES_URL`   | Override URL for querying rocksdb available remote releases.                                                                                     | `none`   |                  |

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
