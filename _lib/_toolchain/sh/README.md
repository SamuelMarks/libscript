# Sh (Toolchain)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `sh` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is Shell Scripting (Sh)?**: Shell scripting (Sh) refers to a computer program designed to be run by the Unix shell, a command-line interpreter. It is widely used for system administration, task automation, and file manipulation.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `sh`. 

### Local and Global Version Management

The `sh` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`. This dual capability allows developers to manage specific versions per project locally or enforce system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build, deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can orchestrate `sh` alongside databases, web servers, and other services to form a cohesive, reproducible stack.

### Usage with LibScript

You can easily install, uninstall, start, stop, or package `sh` utilizing LibScript.

**Unix (Linux/macOS):**
```sh
# Install
./libscript.sh install sh [VERSION] [OPTIONS]

# Uninstall
./libscript.sh uninstall sh

# Start / Stop (if applicable as a service/daemon)
./libscript.sh start sh
./libscript.sh stop sh

# Package
./libscript.sh package_as docker sh
```

**Windows:**
```cmd
:: Install
libscript.cmd install sh [VERSION] [OPTIONS]

:: Uninstall
libscript.cmd uninstall sh

:: Start / Stop (if applicable as a service/daemon)
libscript.cmd start sh
libscript.cmd stop sh

:: Package
libscript.cmd package_as msi sh
```

*Note: Alternatively, you can use `cli.sh` or `cli.cmd` directly within this directory for localized execution.*

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `SH_INSTALL_METHOD` | How to install SH. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
## Variables

See `vars.schema.json` for details on available variables.
