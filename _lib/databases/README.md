Databases
=========

## Purpose & Overview
**Purpose**: This document provides context and technical details for the **Storage folder (`_storage`)** component within the LibScript ecosystem. This directory houses various database and storage solutions (e.g., PostgreSQL, MongoDB, SQLite). 

The components inside this directory work both as local version managers (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for their respective storage technologies, and can be invoked from the global version manager `libscript`. By providing these flexible storage primitives, LibScript can be used to seamlessly build bigger, more complex software stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall databases using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install databases

./cli.sh install databases

./libscript.sh start databases
./cli.sh start databases

./libscript.sh stop databases
./cli.sh stop databases

./libscript.sh package_as docker databases
./cli.sh package_as docker databases

./libscript.sh uninstall databases
./cli.sh uninstall databases
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install databases

:: Local CLI
cli.cmd install databases

:: Start and Stop
libscript.cmd start databases
cli.cmd start databases

libscript.cmd stop databases
cli.cmd stop databases

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi databases
cli.cmd package_as msi databases

:: Uninstall
libscript.cmd uninstall databases
cli.cmd uninstall databases
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

You can override the global setting for specific dependencies by setting their respective `DATABASES_INSTALL_METHOD` variable. The local override takes highest precedence. 

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

## Platform Support
- Linux
- macOS
- Windows
