# Docker (Toolchain)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `docker` component (part of `_server`) within the LibScript ecosystem. Docker is a platform for developing, shipping, and running containerized applications.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `docker`. This component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. 

Furthermore, Docker can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by providing the underlying containerization runtime.

### Usage with LibScript

You can easily manage the lifecycle of Docker using `libscript`. The following commands demonstrate how to install, uninstall, start, stop, and package this component:

**Install**:
```sh
./libscript.sh install docker
```

**Uninstall**:
```sh
./libscript.sh uninstall docker
```

**Start/Stop**:
```sh
./libscript.sh start docker
./libscript.sh stop docker
```

**Package**:
```sh
./libscript.sh package_as docker docker
```

*Note: On Windows, use `libscript.cmd` or `libscript.bat` instead of `./libscript.sh`.*

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `DOCKER_VERSION` | Specific version of docker to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `DOCKER_INSTALL_METHOD` | How to install DOCKER. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `DOCKER_LISTEN_PORT` | Port for DOCKER to listen on | `none` | `` |
| `DOCKER_LISTEN_ADDRESS` | Address for DOCKER to listen on | `none` | `` |
| `DOCKER_LISTEN_SOCKET` | Unix socket for DOCKER to listen on | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.
