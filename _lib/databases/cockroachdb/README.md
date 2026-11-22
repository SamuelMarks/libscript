# cockroachdb

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `cockroachdb` component
(part of `_databases`) within the LibScript ecosystem. Cloud-native distributed SQL database built
for transactional consistency, horizontal scalability, and survivability.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **CockroachDB**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install cockroachdb
libscript uninstall cockroachdb
```

**Start / Stop (if configured as a background service):**

```sh
libscript start cockroachdb
libscript stop cockroachdb
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker cockroachdb
```

_Note: On Unix environments, you can also use `./cli.sh install cockroachdb`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                          | Default            | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `COCKROACHDB_INSTALL_METHOD` | How to install cockroachdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `COCKROACHDB_VERSION`        | Specific version of cockroachdb to install.                                                                                                          | `latest`           | latest, lts      |
| `COCKROACHDB_DOWNLOAD_URL`   | Override URL for downloading cockroachdb binary or archive artifacts.                                                                                | `none`             |                  |
| `COCKROACHDB_RELEASES_URL`   | Override URL for querying cockroachdb available remote releases.                                                                                     | `none`             |                  |
| `COCKROACHDB_LISTEN_PORT`    | TCP port on which the cockroachdb service listens.                                                                                                   | `26257`            |                  |

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
