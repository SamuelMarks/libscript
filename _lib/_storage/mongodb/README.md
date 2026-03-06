# MongoDB (Toolchain)

## Purpose & Overview

This document provides context and technical details for the **MongoDB** component (part of the `_storage` module) within the LibScript ecosystem. MongoDB is a widely used, document-oriented NoSQL database system.

This module works both as a local version manager for MongoDB (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be directly invoked from the global version manager `libscript`. By treating MongoDB as a modular component, LibScript can use it to provision and build bigger, more complex software stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage with LibScript

You can deploy and manage MongoDB directly or through the LibScript CLI.

### Install
**Unix (Linux/macOS):**
```sh
./cli.sh install mongodb [VERSION] [OPTIONS]
# or via global libscript:
libscript install mongodb [VERSION]
```

**Windows:**
```cmd
cli.cmd install mongodb [VERSION] [OPTIONS]
# or via global libscript:
libscript install mongodb [VERSION]
```

### Start / Stop
To manage the MongoDB service:
```sh
libscript start mongodb
libscript stop mongodb
```

### Uninstall
To gracefully remove MongoDB and clean up its data/configurations:
```sh
libscript uninstall mongodb
```

### Package
To generate a deployment configuration or installer for a stack containing MongoDB:
```sh
libscript package_as docker mongodb
libscript package_as msi mongodb
```
*(Supports docker, docker_compose, msi, innosetup, nsis, and TUI).*

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `MONGODB_VERSION` | Specific version of mongodb to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `MONGODB_INSTALL_METHOD` | How to install MONGODB. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `MONGODB_LISTEN_PORT` | Port for MONGODB to listen on | `none` | `` |
| `MONGODB_LISTEN_ADDRESS` | Address for MONGODB to listen on | `none` | `` |
| `MONGODB_LISTEN_SOCKET` | Unix socket for MONGODB to listen on | `none` | `` |
| `MONGODB_DATA_DIR` | Directory for MongoDB data | `none` | `` |
| `MONGODB_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` | `` |
| `MONGODB_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` | `` |
| `MONGODB_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_mongodb` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
