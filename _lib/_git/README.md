# Git (Component)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_git` component (part of `_lib`) within the LibScript ecosystem. This component is responsible for installing, managing, and configuring **Git**, the widely used distributed version control system. It provides the necessary scripts to provision Git across supported operating systems efficiently.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the scripts for managing Git. It is designed to work both as a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for isolated project-level Git installations, and can also be seamlessly invoked from the global version manager `libscript`.

Additionally, this component can be utilized by LibScript as a foundational dependency to build and provision bigger stacks, such as WordPress, Open edX, Nextcloud, and other complex software environments.

### Lifecycle Commands

You can manage the lifecycle of Git (install, uninstall, start, stop, package) via the global router or directly via the component's CLI.

**Unix (Linux/macOS):**
```sh
# Install
./cli.sh install git [VERSION] [OPTIONS]
./libscript.sh install git

# Uninstall
./cli.sh uninstall git
./libscript.sh uninstall git

# Start / Stop (if applicable as a service, though Git is mostly CLI-driven)
./cli.sh start git
./cli.sh stop git

# Package
./cli.sh package_as docker git
```

**Windows:**
```cmd
# Install
cli.cmd install git [VERSION] [OPTIONS]
libscript.cmd install git

# Uninstall
cli.cmd uninstall git
libscript.cmd uninstall git

# Start / Stop
cli.cmd start git
cli.cmd stop git

# Package
cli.cmd package_as msi git
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `1` | repository | `none` | `` |
| `2` | target directory | `none` | `` |
| `3` | branch | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
