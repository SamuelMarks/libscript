# app/third_party

## Overview
This document describes the `third_party` folder within the LibScript ecosystem. This directory houses third-party application modules and integration scripts that are not developed natively as part of LibScript but are orchestrated by it.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. The components within this folder can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.) by pulling together various external dependencies and applications.

## LibScript Operations
You can manage the `third_party` components using the global `libscript` CLI or the local `cli.sh`/`cli.cmd`.

- **Install:** `libscript install third_party`
- **Uninstall:** `libscript uninstall third_party`
- **Start:** `libscript start third_party`
- **Stop:** `libscript stop third_party`
- **Package:** `libscript package_as docker third_party` (or `msi`, `docker_compose`, etc.)

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
