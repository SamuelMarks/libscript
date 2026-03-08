# Storage Folder (`_storage`)

## Purpose & Overview

**Purpose**: This document provides context and technical details for the **Storage folder (`_storage`)** component within the LibScript ecosystem. This directory houses various database and storage solutions (e.g., PostgreSQL, MongoDB, SQLite). 

The components inside this directory work both as local version managers (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for their respective storage technologies, and can be invoked from the global version manager `libscript`. By providing these flexible storage primitives, LibScript can be used to seamlessly build bigger, more complex software stacks (like WordPress, Open edX, Nextcloud, etc.).

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support, robust uninstall lifecycle hooks, and natively supports generating deployment configurations with deep installer customization.

## Usage with LibScript

Every component within the `_storage` directory follows a unified command interface.

### Install
```sh
libscript install <storage_component> [VERSION]
```

### Start / Stop
```sh
libscript start <storage_component>
libscript stop <storage_component>
```

### Uninstall
```sh
libscript uninstall <storage_component>
```

### Package
```sh
libscript package_as docker <storage_component>
libscript package_as msi <storage_component>
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
