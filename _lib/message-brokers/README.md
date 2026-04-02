Message Brokers
===============

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `_daemon` component (a directory under `_lib`) within the LibScript ecosystem. It describes the directory responsible for configuring and managing system service daemons and background tasks across different operating systems.

## Usage
The components inside this directory work both as local version managers (similar to rvm, nvm, pyenv, uv) and can be invoked directly from the global version manager `libscript`. 

Additionally, daemon controllers contained here can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by enabling components to run reliably in the background on system startup.

## Usage
You can install, start, stop, package, and uninstall message-brokers using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install message-brokers

./cli.sh install message-brokers

./libscript.sh start message-brokers
./cli.sh start message-brokers

./libscript.sh stop message-brokers
./cli.sh stop message-brokers

./libscript.sh package_as docker message-brokers
./cli.sh package_as docker message-brokers

./libscript.sh uninstall message-brokers
./cli.sh uninstall message-brokers
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install message-brokers

:: Local CLI
cli.cmd install message-brokers

:: Start and Stop
libscript.cmd start message-brokers
cli.cmd start message-brokers

libscript.cmd stop message-brokers
cli.cmd stop message-brokers

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi message-brokers
cli.cmd package_as msi message-brokers

:: Uninstall
libscript.cmd uninstall message-brokers
cli.cmd uninstall message-brokers
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

You can override the global setting for specific dependencies by setting their respective `MESSAGE_BROKERS_INSTALL_METHOD` variable. The local override takes highest precedence. 

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
