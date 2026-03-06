# Noop (Core Library)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_noop` component (part of `_common`) within the LibScript ecosystem. This module serves as a "no-operation" (noop) placeholder or dummy component. It is primarily used for testing, structural padding, or safely bypassing execution paths where a component is required but no actual operation should be performed.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the configuration scripts for `_noop`. Despite being a dummy component, it is designed to strictly follow the standard LibScript architecture. It works both as a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager `libscript`.

Additionally, the `_noop` module can be utilized by LibScript when dynamically assembling and building bigger stacks (like WordPress, Open edX, Nextcloud), acting as a safe fallback when specific dependencies are disabled or intentionally omitted from a stack deployment.

### Lifecycle Commands

You can simulate the lifecycle of `_noop` (install, uninstall, start, stop, package) via the global router or directly via the component's CLI. These commands perform no actual changes but validate the pipeline.

**Unix (Linux/macOS):**
```sh
# Install
./cli.sh install noop [VERSION] [OPTIONS]
./libscript.sh install noop

# Uninstall
./cli.sh uninstall noop
./libscript.sh uninstall noop

# Start / Stop
./cli.sh start noop
./cli.sh stop noop

# Package
./cli.sh package_as docker noop
```

**Windows:**
```cmd
# Install
cli.cmd install noop [VERSION] [OPTIONS]
libscript.cmd install noop

# Uninstall
cli.cmd uninstall noop
libscript.cmd uninstall noop

# Start / Stop
cli.cmd start noop
cli.cmd stop noop

# Package
cli.cmd package_as msi noop
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
