Valkey
======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `valkey` component (part of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation, configuration, and lifecycle management scripts for **Valkey**. 

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) for managing isolated instances of Valkey, and it can be invoked seamlessly from the **global version manager**, `libscript`. 

Furthermore, `libscript` can utilize this Valkey component as a foundational building block to provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

## Usage
You can install, start, stop, package, and uninstall valkey using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install valkey 

./cli.sh install valkey 

./libscript.sh start valkey
./cli.sh start valkey

./libscript.sh stop valkey
./cli.sh stop valkey

./libscript.sh package_as docker valkey
./cli.sh package_as docker valkey

./libscript.sh uninstall valkey
./cli.sh uninstall valkey
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install valkey 

:: Local CLI
cli.cmd install valkey 

:: Start and Stop
libscript.cmd start valkey
cli.cmd start valkey

libscript.cmd stop valkey
cli.cmd stop valkey

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi valkey
cli.cmd package_as msi valkey

:: Uninstall
libscript.cmd uninstall valkey
cli.cmd uninstall valkey
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `VALKEY_BUILD_DIR` | Directory to build valkey from | `none` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `VALKEY_LISTEN_PORT` | Port for VALKEY to listen on | `none` | `` |
| `VALKEY_LISTEN_ADDRESS` | Address for VALKEY to listen on | `none` | `` |
| `VALKEY_LISTEN_SOCKET` | Unix socket for VALKEY to listen on | `none` | `` |
| `VALKEY_DATA_DIR` | Directory for Valkey data | `none` | `` |
| `VALKEY_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` | `` |
| `VALKEY_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` | `` |
| `VALKEY_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_valkey` | `` |

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
