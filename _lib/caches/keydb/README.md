# keydb

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `keydb` component (part of
`_caches`) within the LibScript ecosystem. High-performance multithreaded fork of Redis focusing on
active-active replication and flash storage.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **KeyDB**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install keydb
libscript uninstall keydb
```

**Start / Stop (if configured as a background service):**

```sh
libscript start keydb
libscript stop keydb
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker keydb
```

_Note: On Unix environments, you can also use `./cli.sh install keydb`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `KEYDB_INSTALL_METHOD` | How to install keydb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `KEYDB_VERSION`        | Specific version of keydb to install.                                                                                                          | `latest` | latest, lts      |
| `KEYDB_DOWNLOAD_URL`   | Override URL for downloading keydb binary or archive artifacts.                                                                                | `none`   |                  |
| `KEYDB_RELEASES_URL`   | Override URL for querying keydb available remote releases.                                                                                     | `none`   |                  |
| `KEYDB_LISTEN_PORT`    | TCP port on which the keydb service listens.                                                                                                   | `6379`   |                  |

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
