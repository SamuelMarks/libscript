# Redis

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `redis` component (part of
`_caches`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**Redis**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of Redis, and it can be invoked seamlessly
from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this Redis component as a foundational building block to
provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

You can install, start, stop, package, and uninstall redis using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh
./libscript.sh install redis
./cli.sh install redis

./libscript.sh start redis
./cli.sh start redis

./libscript.sh stop redis
./cli.sh stop redis

./libscript.sh package_as docker redis
./cli.sh package_as docker redis

./libscript.sh uninstall redis
./cli.sh uninstall redis
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install redis

:: Local CLI
cli.cmd install redis

:: Start and Stop
libscript.cmd start redis
cli.cmd start redis

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi redis
cli.cmd package_as msi redis

:: Uninstall
libscript.cmd uninstall redis
cli.cmd uninstall redis
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                              | Default  | Aliases/Examples |
| --------------------------------- | -------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed (system vs source).                                 | `system` |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`       | Global package manager override for Windows (winget, choco).                                             | `winget` |                  |
| `LIBSCRIPT_LOG_LEVEL`             | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                     | `1`      |                  |
| `LIBSCRIPT_LOG_FORMAT`            | Output format for logs (text, json).                                                                     | `text`   |                  |
| `LIBSCRIPT_LOG_FILE`              | File to write logs to (in addition to standard output).                                                  | `none`   |                  |
| `LIBSCRIPT_SERVICE_NAME`          | Overrides the default service name.                                                                      | `none`   |                  |
| `DOWNLOAD_DIR`                    | Directory where downloads are stored.                                                                    | `none`   |                  |
| `FORMAT`                          | Output format (e.g., json, text).                                                                        | `none`   |                  |
| `LIBSCRIPT_CACHE_DIR`             | Directory where cached files are stored.                                                                 | `none`   |                  |
| `LIBSCRIPT_LOG_DRIVER`            | Logging driver to use (e.g., fluentd).                                                                   | `none`   |                  |
| `LOGS_DIR`                        | Directory where logs should be stored.                                                                   | `none`   |                  |
| `VAULT_TOKEN`                     | Token for HashiCorp Vault authentication.                                                                | `none`   |                  |
| `PREFIX`                          | Installation prefix.                                                                                     | `none`   |                  |
| `SERVE_FROM`                      | Base directory or context path for the service.                                                          | `none`   |                  |
| `LIBSCRIPT_LOG_HOST`              | Host for remote logging.                                                                                 | `none`   |                  |
| `LIBSCRIPT_VERSION`               | Specifies the version of the package to use.                                                             | `none`   |                  |
| `LIBSCRIPT_LOG_PORT`              | Port for remote logging.                                                                                 | `none`   |                  |
| `REDIS_VERSION`                   | Specific version of redis to install. Can be a numeric version or an alias.                              | `latest` | latest, stable   |
| `REDIS_INSTALL_METHOD`            | How to install REDIS. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `source` |                  |
| `LIBSCRIPT_LISTEN_PORT`           | Global port to listen on                                                                                 | `none`   |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`        | Global address to listen on                                                                              | `none`   |                  |
| `LIBSCRIPT_LISTEN_SOCKET`         | Global unix socket to listen on                                                                          | `none`   |                  |
| `REDIS_LISTEN_PORT`               | Port for REDIS to listen on                                                                              | `none`   |                  |
| `REDIS_LISTEN_ADDRESS`            | Address for REDIS to listen on                                                                           | `none`   |                  |
| `REDIS_LISTEN_SOCKET`             | Unix socket for REDIS to listen on                                                                       | `none`   |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
