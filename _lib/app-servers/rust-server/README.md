# Rust Server

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `rust` component within
the LibScript ecosystem. This component manages a **Rust server** environment.

## Usage

This directory contains the scripts to interact with `rust`. It is designed to be executed via the
global `libscript` command or directly via local CLI scripts.

You can install, start, stop, uninstall, and package this component using `libscript`.

**Install:**

```sh
libscript install rust
```

**Start:**

```sh
libscript start rust
```

**Stop:**

```sh
libscript stop rust
```

**Uninstall:**

```sh
libscript uninstall rust
```

**Package:**

```sh
libscript package_as docker rust

```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                              | Default  | Aliases/Examples |
| --------------------------------- | ------------------------------------------------------------------------ | -------- | ---------------- |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed (system vs source). | `system` |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`       | Global package manager override for Windows (winget, choco).             | `winget` |                  |
| `LIBSCRIPT_LOG_LEVEL`             | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).     | `1`      |                  |
| `LIBSCRIPT_LOG_FORMAT`            | Output format for logs (text, json).                                     | `text`   |                  |
| `LIBSCRIPT_LOG_FILE`              | File to write logs to (in addition to standard output).                  | `none`   |                  |
| `LIBSCRIPT_SERVICE_NAME`          | Overrides the default service name.                                      | `none`   |                  |
| `DOWNLOAD_DIR`                    | Directory where downloads are stored.                                    | `none`   |                  |
| `FORMAT`                          | Output format (e.g., json, text).                                        | `none`   |                  |
| `LIBSCRIPT_CACHE_DIR`             | Directory where cached files are stored.                                 | `none`   |                  |
| `LIBSCRIPT_LOG_DRIVER`            | Logging driver to use (e.g., fluentd).                                   | `none`   |                  |
| `LOGS_DIR`                        | Directory where logs should be stored.                                   | `none`   |                  |
| `VAULT_TOKEN`                     | Token for HashiCorp Vault authentication.                                | `none`   |                  |
| `PREFIX`                          | Installation prefix.                                                     | `none`   |                  |
| `SERVE_FROM`                      | Base directory or context path for the service.                          | `none`   |                  |
| `LIBSCRIPT_LOG_HOST`              | Host for remote logging.                                                 | `none`   |                  |
| `LIBSCRIPT_VERSION`               | Specifies the version of the package to use.                             | `none`   |                  |
| `LIBSCRIPT_LOG_PORT`              | Port for remote logging.                                                 | `none`   |                  |
| `RUST_SERVER_DEST`                | Destination (working directory)                                          | `none`   |                  |
| `RUST_SERVER_VARS`                | Key/value in JSON format (as an escaped string)                          | `none`   |                  |
| `LIBSCRIPT_LISTEN_PORT`           | Global port to listen on                                                 | `none`   |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`        | Global address to listen on                                              | `none`   |                  |
| `LIBSCRIPT_LISTEN_SOCKET`         | Global unix socket to listen on                                          | `none`   |                  |
| `RUST_SERVER_LISTEN_PORT`         | Port for RUST to listen on                                               | `none`   |                  |
| `RUST_SERVER_LISTEN_ADDRESS`      | Address for RUST to listen on                                            | `none`   |                  |
| `RUST_SERVER_LISTEN_SOCKET`       | Unix socket for RUST to listen on                                        | `none`   |                  |

<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
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
