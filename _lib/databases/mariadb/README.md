MariaDB
=======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `mariadb` component (part of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation, configuration, and lifecycle management scripts for **MariaDB**. 

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) for managing isolated instances of MariaDB, and it can be invoked seamlessly from the **global version manager**, `libscript`. 

Furthermore, `libscript` can utilize this MariaDB component as a foundational database building block to provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

## Usage
You can install, start, stop, package, and uninstall mariadb using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

libscript install mariadb 

libscript start mariadb
libscript stop mariadb

libscript package_as docker mariadb

libscript uninstall mariadb
```

**Windows:**
```cmd
:: Install
libscript.cmd install mariadb 

:: Start and Stop
libscript.cmd start mariadb
libscript.cmd stop mariadb

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi mariadb

:: Uninstall
libscript.cmd uninstall mariadb
```

*Alternatively, you can execute these locally from within this directory using `./cli.sh install mariadb` or `cli.cmd install mariadb`.*

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `MARIADB_VERSION` | Specific version of mariadb to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `MARIADB_INSTALL_METHOD` | How to install MARIADB. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `MARIADB_LISTEN_PORT` | Port for MARIADB to listen on | `none` | `` |
| `MARIADB_LISTEN_ADDRESS` | Address for MARIADB to listen on | `none` | `` |
| `MARIADB_LISTEN_SOCKET` | Unix socket for MARIADB to listen on | `none` | `` |
| `MARIADB_DATA_DIR` | Directory for MariaDB data | `none` | `` |
| `MARIADB_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` | `` |
| `MARIADB_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` | `` |
| `MARIADB_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_mariadb` | `` |

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
