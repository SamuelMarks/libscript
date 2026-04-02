PostgreSQL
==========

## Purpose & Overview
This document provides context and technical details for the **PostgreSQL** component (part of the `_storage` directory) within the LibScript ecosystem. PostgreSQL is a powerful, open-source object-relational database system.

This module works both as a local version manager for PostgreSQL (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be directly invoked from the global version manager `libscript`. Because of this flexibility, PostgreSQL can be utilized by LibScript to provision and build bigger, more complex software stacks (such as WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall postgres using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install postgres

./cli.sh install postgres

./libscript.sh start postgres
./cli.sh start postgres

./libscript.sh stop postgres
./cli.sh stop postgres

./libscript.sh package_as docker postgres
./cli.sh package_as docker postgres

./libscript.sh uninstall postgres
./cli.sh uninstall postgres
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install postgres

:: Local CLI
cli.cmd install postgres

:: Start and Stop
libscript.cmd start postgres
cli.cmd start postgres

libscript.cmd stop postgres
cli.cmd stop postgres

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi postgres
cli.cmd package_as msi postgres

:: Uninstall
libscript.cmd uninstall postgres
cli.cmd uninstall postgres
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `POSTGRESQL_VERSION` | Version of PostgreSQL demanded | `none` | `` |
| `POSTGRES_USER` | Username to create inside postgres | `none` | `` |
| `POSTGRES_PASSWORD` | Password for created user inside postgres | `none` | `` |
| `POSTGRES_PASSWORD_FILE` | Password file, its contents used as password for created user inside postgres | `none` | `` |
| `POSTGRES_SERVICE_USER` | Username for superuser & system role | `none` | `` |
| `POSTGRES_SERVICE_PASSWORD` | Password for postgres user; fallsback to `POSTGRES_PASSWORD` | `none` | `` |
| `POSTGRES_HOST` | Hostname to serve postgres from | `none` | `` |
| `POSTGRES_DB` | Database to create within postgres | `none` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `POSTGRES_LISTEN_PORT` | Port for POSTGRES to listen on | `none` | `` |
| `POSTGRES_LISTEN_ADDRESS` | Address for POSTGRES to listen on | `none` | `` |
| `POSTGRES_LISTEN_SOCKET` | Unix socket for POSTGRES to listen on | `none` | `` |
| `POSTGRES_DATA_DIR` | Directory for PostgreSQL data cluster | `none` | `` |
| `POSTGRES_LOCALE` | Locale for PostgreSQL initdb (e.g. English, United States) | `none` | `` |
| `POSTGRES_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` | `` |
| `POSTGRES_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` | `` |
| `POSTGRES_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_postgres` | `` |

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
