# C (Toolchain)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `c` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is C?**: C is a powerful, general-purpose procedural computer programming language supporting structured programming, lexical variable scope, and recursion, widely used for system programming and embedded systems.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `c`. 

### Local and Global Version Management

The `c` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`. This dual capability allows developers to manage specific versions per project locally or enforce system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build, deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can orchestrate `c` toolchains alongside databases, web servers, and other services to form a cohesive, reproducible stack.

### Usage with LibScript

You can easily install, uninstall, start, stop, or package `c` toolchains using LibScript.

**Unix (Linux/macOS):**
```sh
# Install
./libscript.sh install c [VERSION] [OPTIONS]

# Uninstall
./libscript.sh uninstall c

# Start / Stop (if applicable as a service/daemon)
./libscript.sh start c
./libscript.sh stop c

# Package
./libscript.sh package_as docker c
```

**Windows:**
```cmd
:: Install
libscript.cmd install c [VERSION] [OPTIONS]

:: Uninstall
libscript.cmd uninstall c

:: Start / Stop (if applicable as a service/daemon)
libscript.cmd start c
libscript.cmd stop c

:: Package
libscript.cmd package_as msi c
```

*Note: Alternatively, you can use `cli.sh` or `cli.cmd` directly within this directory for localized execution.*

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `C_INSTALL_METHOD` | How to install C. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.