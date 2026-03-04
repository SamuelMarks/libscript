# Postgres (Storage/Database)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `postgres` component (part of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `postgres`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Installation

**Unix (Linux/macOS):**
```sh
./cli.sh <COMMAND> <PACKAGE_NAME> [VERSION] [OPTIONS]
```

**Windows:**
```cmd
cli.cmd <COMMAND> <PACKAGE_NAME> [VERSION] [OPTIONS]
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

