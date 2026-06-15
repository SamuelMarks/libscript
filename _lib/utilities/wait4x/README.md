# Wait4X

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `wait4x` component (part
of `_toolchain`) within the LibScript ecosystem. `wait4x` is a command-line tool that allows you to
wait for various ports and services (like databases, HTTP servers, or generic TCP sockets) to become
available, making it invaluable for reliable CI/CD and orchestration flows.

Crucially, this module allows `wait4x` to function both as a **local version manager** (similar to
tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global
version manager, `libscript`. Furthermore, `libscript` can utilize this `wait4x` toolchain as a
foundational building block to provision and orchestrate much larger, complex software stacks (such
as WordPress, Open edX, Nextcloud, and more) where service startup synchronization is required.

## Usage with LibScript

This directory contains the installation and configuration scripts for `wait4x`. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

You can install, start, stop, package, and uninstall wait4x using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install wait4x

./cli.sh install wait4x

./libscript.sh start wait4x
./cli.sh start wait4x

./libscript.sh stop wait4x
./cli.sh stop wait4x

./libscript.sh package_as docker wait4x
./cli.sh package_as docker wait4x

./libscript.sh uninstall wait4x
./cli.sh uninstall wait4x
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install wait4x

:: Local CLI
cli.cmd install wait4x

:: Start and Stop
libscript.cmd start wait4x
cli.cmd start wait4x

libscript.cmd stop wait4x
cli.cmd stop wait4x

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi wait4x
cli.cmd package_as msi wait4x

:: Uninstall
libscript.cmd uninstall wait4x
cli.cmd uninstall wait4x
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
| `WAIT4X_VERSION`                  | Specific version of Wait4X to install.                                   | `latest` |                  |

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
