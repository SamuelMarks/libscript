MongoDB
=======

## Purpose & Overview
This document provides context and technical details for the **MongoDB** component (part of the `_storage` module) within the LibScript ecosystem. MongoDB is a widely used, document-oriented NoSQL database system.

This module works both as a local version manager for MongoDB (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be directly invoked from the global version manager `libscript`. By treating MongoDB as a modular component, LibScript can use it to provision and build bigger, more complex software stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall mongodb using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install mongodb

./cli.sh install mongodb

./libscript.sh start mongodb
./cli.sh start mongodb

./libscript.sh stop mongodb
./cli.sh stop mongodb

./libscript.sh package_as docker mongodb
./cli.sh package_as docker mongodb

./libscript.sh uninstall mongodb
./cli.sh uninstall mongodb
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install mongodb

:: Local CLI
cli.cmd install mongodb

:: Start and Stop
libscript.cmd start mongodb
cli.cmd start mongodb

libscript.cmd stop mongodb
cli.cmd stop mongodb

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi mongodb
cli.cmd package_as msi mongodb

:: Uninstall
libscript.cmd uninstall mongodb
cli.cmd uninstall mongodb
```

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

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
