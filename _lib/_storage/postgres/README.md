# PostgreSQL (Storage/Database)

## Purpose & Overview

This document provides context and technical details for the **PostgreSQL** component (part of the `_storage` directory) within the LibScript ecosystem. PostgreSQL is a powerful, open-source object-relational database system.

This module works both as a local version manager for PostgreSQL (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be directly invoked from the global version manager `libscript`. Because of this flexibility, PostgreSQL can be utilized by LibScript to provision and build bigger, more complex software stacks (such as WordPress, Open edX, Nextcloud, etc.).

## Usage with LibScript

You can manage your PostgreSQL instance via the LibScript CLI router or locally.

### Install
**Unix (Linux/macOS):**
```sh
./cli.sh install postgres [VERSION] [OPTIONS]
# or via global libscript:
libscript install postgres [VERSION]
```

**Windows:**
```cmd
cli.cmd install postgres [VERSION] [OPTIONS]
# or via global libscript:
libscript install postgres [VERSION]
```

### Start / Stop
To manage the PostgreSQL service lifecycle:
```sh
libscript start postgres
libscript stop postgres
```

### Uninstall
To cleanly remove PostgreSQL binaries, services, and associated configurations:
```sh
libscript uninstall postgres
```

### Package
To generate deployment configurations or installers containing PostgreSQL:
```sh
libscript package_as docker postgres
libscript package_as msi postgres
```
*(Supports docker, docker_compose, msi, innosetup, nsis, and TUI).*

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
