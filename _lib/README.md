# Lib (Core Library Directory)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_lib` directory within the LibScript ecosystem. This directory is the central repository for all supported components, toolchains, servers, and services that LibScript can manage. It contains the modular definitions required to provision and configure software dynamically.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

The `_lib` ecosystem is designed so that each included module acts both as a standalone local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`), allowing isolated installations, and can be centrally invoked and orchestrated via the global version manager `libscript`.

Most importantly, the components within `_lib` are the building blocks that can be used by LibScript to seamlessly provision and build bigger, complex stacks (such as WordPress, Open edX, Nextcloud, etc.).

### Lifecycle Commands

You can manage the lifecycle of any component within `_lib` (install, uninstall, start, stop, package) via the global router.

**Unix (Linux/macOS):**
```sh
# Install a component
./libscript.sh install <COMPONENT_NAME> [VERSION]

# Uninstall a component
./libscript.sh uninstall <COMPONENT_NAME>

# Start / Stop a component's service
./libscript.sh start <COMPONENT_NAME>
./libscript.sh stop <COMPONENT_NAME>

# Package a component
./libscript.sh package_as docker <COMPONENT_NAME>
```

**Windows:**
```cmd
# Install a component
libscript.cmd install <COMPONENT_NAME> [VERSION]

# Uninstall a component
libscript.cmd uninstall <COMPONENT_NAME>

# Start / Stop a component's service
libscript.cmd start <COMPONENT_NAME>
libscript.cmd stop <COMPONENT_NAME>

# Package a component
libscript.cmd package_as msi <COMPONENT_NAME>
```

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
