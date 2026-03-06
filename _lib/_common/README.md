# Common (Component)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_common` component (part of `_lib`) within the LibScript ecosystem. This component provides shared utilities, core functions, and baseline scripts that are universally utilized by other modules across the LibScript framework to ensure consistent execution across different platforms.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the essential shared scripts for `_common`. It is designed to work both as a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for managing common toolkit versions, and can be seamlessly invoked from the global version manager `libscript`.

Furthermore, these common utilities are foundational and can be used by LibScript to build and provision bigger stacks, such as WordPress, Open edX, Nextcloud, and other enterprise-grade application deployments.

### Lifecycle Commands

You can manage the lifecycle of the `_common` toolkit (install, uninstall, start, stop, package) via the global router or directly via the component's CLI.

**Unix (Linux/macOS):**
```sh
# Install
./cli.sh install common [VERSION] [OPTIONS]
./libscript.sh install common

# Uninstall
./cli.sh uninstall common
./libscript.sh uninstall common

# Start / Stop (if running daemonized utilities)
./cli.sh start common
./cli.sh stop common

# Package
./cli.sh package_as docker common
```

**Windows:**
```cmd
# Install
cli.cmd install common [VERSION] [OPTIONS]
libscript.cmd install common

# Uninstall
cli.cmd uninstall common
libscript.cmd uninstall common

# Start / Stop
cli.cmd start common
cli.cmd stop common

# Package
cli.cmd package_as msi common
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
