Toolchains
==========

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `_toolchain` component (part of `_lib`) within the LibScript ecosystem. The `_toolchain` module acts as a collection of provisioning scripts and configuration logic for various programming languages, compilers, and development environments (such as Python, Rust, Node, Go, etc.). LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
The `_toolchain` module encompasses the lifecycle management of different programming environments. Every individual toolchain within this module works both as a local version manager (similar to rvm, nvm, pyenv, uv) for its respective technology, and can be seamlessly invoked from the global version manager `libscript`. Furthermore, these toolchains can be used by libscript to build and compose bigger, more complex stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall toolchains using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install toolchains

./cli.sh install toolchains

./libscript.sh start toolchains
./cli.sh start toolchains

./libscript.sh stop toolchains
./cli.sh stop toolchains

./libscript.sh package_as docker toolchains
./cli.sh package_as docker toolchains

./libscript.sh uninstall toolchains
./cli.sh uninstall toolchains
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install toolchains

:: Local CLI
cli.cmd install toolchains

:: Start and Stop
libscript.cmd start toolchains
cli.cmd start toolchains

libscript.cmd stop toolchains
cli.cmd stop toolchains

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi toolchains
cli.cmd package_as msi toolchains

:: Uninstall
libscript.cmd uninstall toolchains
cli.cmd uninstall toolchains
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

You can override the global setting for specific dependencies by setting their respective `TOOLCHAINS_INSTALL_METHOD` variable. The local override takes highest precedence. 

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
