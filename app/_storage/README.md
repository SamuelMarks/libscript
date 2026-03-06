app/_storage
============

## Purpose & Overview

This document describes the `_storage` component (a collection of database and storage tools) within the LibScript ecosystem.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript` command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for these storage solutions. You can manage storage dependencies directly in an isolated, local context, or orchestrate them globally. 

Furthermore, the `_storage` components can be seamlessly utilized by LibScript to build and provision larger, complex stacks (like WordPress, Open edX, Nextcloud, etc.) by defining them as dependencies in your deployment configurations.

## Lifecycle Management with LibScript

You can easily install, uninstall, start, stop, and package storage components (like PostgreSQL, MySQL, SQLite, etc.) using the LibScript CLI:

### Installation
**Unix (Linux/macOS):**
```sh
./cli.sh install <STORAGE_COMPONENT> [VERSION] [OPTIONS]
# Or via global manager:
libscript install <STORAGE_COMPONENT>
```

### Start & Stop
```sh
./cli.sh start <STORAGE_COMPONENT>
./cli.sh stop <STORAGE_COMPONENT>
```

### Uninstallation
```sh
./cli.sh uninstall <STORAGE_COMPONENT>
```

### Packaging
LibScript can package storage components into various deployment formats:
```sh
libscript package_as docker <STORAGE_COMPONENT>
libscript package_as msi <STORAGE_COMPONENT>
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

The Python toolchain (`_lib/_toolchain/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.
