# Valkey (Storage/Database)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `valkey` component (part of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation, configuration, and lifecycle management scripts for **Valkey**. 

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) for managing isolated instances of Valkey, and it can be invoked seamlessly from the **global version manager**, `libscript`. 

Furthermore, `libscript` can utilize this Valkey component as a foundational building block to provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

### Lifecycle Management (Install, Start, Stop, Package, Uninstall)

You can install, start, stop, package, and uninstall Valkey using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh
# Install
libscript install valkey [VERSION] [OPTIONS]

# Start and Stop
libscript start valkey
libscript stop valkey

# Package (e.g., as Docker image)
libscript package_as docker valkey

# Uninstall
libscript uninstall valkey
```

**Windows:**
```cmd
:: Install
libscript.cmd install valkey [VERSION] [OPTIONS]

:: Start and Stop
libscript.cmd start valkey
libscript.cmd stop valkey

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi valkey

:: Uninstall
libscript.cmd uninstall valkey
```

*Alternatively, you can execute these locally from within this directory using `./cli.sh <COMMAND> valkey` or `cli.cmd <COMMAND> valkey`.*

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

