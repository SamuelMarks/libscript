Openrc
======

## Usage
This document describes the **OpenRC** component (part of the `_daemon` stack) within the LibScript ecosystem. OpenRC is a dependency-based init system that works with the system-provided init program.

This component functions both as a **local version manager** (similar to rvm, nvm, pyenv, uv) for OpenRC setups and can also be invoked seamlessly from the **global version manager**, `libscript`. Because of this flexibility, OpenRC can be utilized by `libscript` to build and manage services for bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall openrc using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install openrc

./cli.sh install openrc

./libscript.sh start openrc
./cli.sh start openrc

./libscript.sh stop openrc
./cli.sh stop openrc

./libscript.sh package_as docker openrc
./cli.sh package_as docker openrc

./libscript.sh uninstall openrc
./cli.sh uninstall openrc
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install openrc

:: Local CLI
cli.cmd install openrc

:: Start and Stop
libscript.cmd start openrc
cli.cmd start openrc

libscript.cmd stop openrc
cli.cmd stop openrc

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi openrc
cli.cmd package_as msi openrc

:: Uninstall
libscript.cmd uninstall openrc
cli.cmd uninstall openrc
```

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `openrc` component (part of `_daemon`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

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

You can override the global setting for specific dependencies by setting their respective `OPENRC_INSTALL_METHOD` variable. The local override takes highest precedence. 

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
