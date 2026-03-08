_lib/toolchains
===============

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_toolchain` component (part of `_lib`) within the LibScript ecosystem. The `_toolchain` module acts as a collection of provisioning scripts and configuration logic for various programming languages, compilers, and development environments (such as Python, Rust, Node, Go, etc.). LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

The `_toolchain` module encompasses the lifecycle management of different programming environments. Every individual toolchain within this module works both as a local version manager (similar to rvm, nvm, pyenv, uv) for its respective technology, and can be seamlessly invoked from the global version manager `libscript`. Furthermore, these toolchains can be used by libscript to build and compose bigger, more complex stacks (like WordPress, Open edX, Nextcloud, etc.).

### Usage with LibScript

You can manage the lifecycle of any toolchain using the `libscript` CLI.

**Install / Uninstall / Start / Stop / Package:**

```sh
# Install a toolchain (e.g., nodejs)
./libscript.sh install nodejs [VERSION] [OPTIONS]

# Uninstall a toolchain
./libscript.sh uninstall nodejs

# Start a toolchain (if applicable as a daemon/background process)
./libscript.sh start nodejs

# Stop a toolchain (if applicable)
./libscript.sh stop nodejs

# Package a toolchain
./libscript.sh package_as docker nodejs
```
*(On Windows, use `libscript.cmd` or `libscript.bat` instead of `./libscript.sh`)*

## Dependency Installation Methods

`libscript` provides a flexible dependency management system, allowing you to control how dependencies are installed—either globally across the entire setup or locally on a per-toolchain basis.

### Global Configuration

You can set a global preference for how tools should be installed by defining `LIBSCRIPT_GLOBAL_INSTALL_METHOD` in your environment or global configuration (`install.json`).

Supported global methods typically include:
- `system`: Uses the system's package manager (e.g., `apt`, `apk`, `pacman`).
- `source`: Builds or downloads the tool from source/official binaries (fallback behavior depends on the tool).

Example:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
```

### Local Overrides

You can override the global setting for specific dependencies by setting their respective `[TOOL]_INSTALL_METHOD` variable. The local override takes highest precedence. 

For example, to globally use the system package manager but strictly install Python via `uv`:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
export PYTHON_INSTALL_METHOD="uv"
```

### Python-Specific Support

The Python toolchain (`_lib/languages/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.
