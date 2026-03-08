# OpenBao (Server)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `openbao` component (part of `_server`) within the LibScript ecosystem. OpenBao is an open-source tool for managing secrets and protecting sensitive data.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `openbao`. This component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. 

Furthermore, OpenBao can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by providing secure secrets management to these applications.

### Usage with LibScript

You can easily manage the lifecycle of OpenBao using `libscript`. The following commands demonstrate how to install, uninstall, start, stop, and package this component:

**Install**:
```sh
./libscript.sh install openbao
```

**Uninstall**:
```sh
./libscript.sh uninstall openbao
```

**Start/Stop**:
```sh
./libscript.sh start openbao
./libscript.sh stop openbao
```

**Package**:
```sh
./libscript.sh package_as docker openbao
```

*Note: On Windows, use `libscript.cmd` or `libscript.bat` instead of `./libscript.sh`.*

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `OPENBAO_VERSION` | Specific version of openbao to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `OPENBAO_INSTALL_METHOD` | How to install OPENBAO. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `OPENBAO_LISTEN_PORT` | Port for OPENBAO to listen on | `none` | `` |
| `OPENBAO_LISTEN_ADDRESS` | Address for OPENBAO to listen on | `none` | `` |
| `OPENBAO_LISTEN_SOCKET` | Unix socket for OPENBAO to listen on | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.
