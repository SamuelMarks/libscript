# SQLite (Toolchain)

## Purpose & Overview

This document provides context and technical details for the **SQLite** component (part of the `_storage` module) within the LibScript ecosystem. SQLite is a C-language library that implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine.

This component works both as a local version manager for SQLite (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be natively invoked from the global version manager `libscript`. Because of this flexibility, SQLite can be used by LibScript to provision and build bigger, more complex software stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage with LibScript

You can manage SQLite using the standard LibScript commands.

### Install
**Unix (Linux/macOS):**
```sh
./cli.sh install sqlite [VERSION] [OPTIONS]
# or via global libscript:
libscript install sqlite [VERSION]
```

**Windows:**
```cmd
cli.cmd install sqlite [VERSION] [OPTIONS]
# or via global libscript:
libscript install sqlite [VERSION]
```

### Start / Stop
If you are running an application or service that utilizes SQLite in a persistent manner:
```sh
libscript start sqlite
libscript stop sqlite
```

### Uninstall
To clean up binaries, data, and configurations:
```sh
libscript uninstall sqlite
```

### Package
To package SQLite or a stack depending on SQLite into an installer or container:
```sh
libscript package_as docker sqlite
libscript package_as msi sqlite
```
*(Supports docker, docker_compose, msi, innosetup, nsis, and TUI).*

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `SQLITE_VERSION` | Specific version of sqlite to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `SQLITE_INSTALL_METHOD` | How to install SQLITE. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `SQLITE_LISTEN_PORT` | Port for SQLITE to listen on | `none` | `` |
| `SQLITE_LISTEN_ADDRESS` | Address for SQLITE to listen on | `none` | `` |
| `SQLITE_LISTEN_SOCKET` | Unix socket for SQLITE to listen on | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
