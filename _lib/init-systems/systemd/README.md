# Systemd (Component)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `systemd` component (part of `_daemon`) within the LibScript ecosystem. This component configures and manages systemd unit files, enabling applications to run as standard background services on compatible Linux distributions.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `systemd`. This component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. 

Furthermore, systemd integrations can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by ensuring system processes are monitored, restarted on failure, and initiated at boot.

### Usage with LibScript

You can easily manage the lifecycle of systemd configurations using `libscript`. The following commands demonstrate how to install, uninstall, start, stop, and package this component:

**Install**:
```sh
./libscript.sh install systemd
```

**Uninstall**:
```sh
./libscript.sh uninstall systemd
```

**Start/Stop**:
```sh
./libscript.sh start systemd
./libscript.sh stop systemd
```

**Package**:
```sh
./libscript.sh package_as docker systemd
```

*Note: On Windows, use `libscript.cmd` or `libscript.bat` instead of `./libscript.sh`.*

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `EXEC_START` | Executor | `none` | `` |
| `WORKING_DIR` | Working directory that `EXEC_START` will be run from | `none` | `` |
| `ENV` | Optional additional properties as key/value pairs | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.
