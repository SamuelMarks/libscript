Web Servers
===========

## Purpose & Current State
**Purpose**: This document describes the `_server` folder, which houses various server components within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory serves as the root for various server components (like Nginx, Caddy, HTTPD, Python, etc.). Every component within this folder works both as a local version manager (similar to rvm, nvm, pyenv, uv) for precise software version control, and can be invoked seamlessly from the global version manager `libscript`.

Furthermore, the server components housed here can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.), allowing for complex, multi-tier architectures.

## Usage
You can manage the lifecycle of any server component located in this directory using the global `libscript` command or the local CLI. For example, replacing `web-servers` with a component like `nginx` or `caddy`:

**Unix (Linux/macOS):**
```sh

./libscript.sh install web-servers

./cli.sh install web-servers

./libscript.sh start web-servers
./cli.sh start web-servers

./libscript.sh stop web-servers
./cli.sh stop web-servers

./libscript.sh package_as docker web-servers
./cli.sh package_as docker web-servers

./libscript.sh uninstall web-servers
./cli.sh uninstall web-servers
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install web-servers

:: Local CLI
cli.cmd install web-servers

:: Start and Stop
libscript.cmd start web-servers
cli.cmd start web-servers

libscript.cmd stop web-servers
cli.cmd stop web-servers

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi web-servers
cli.cmd package_as msi web-servers

:: Uninstall
libscript.cmd uninstall web-servers
cli.cmd uninstall web-servers
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

You can override the global setting for specific dependencies by setting their respective `WEB_SERVERS_INSTALL_METHOD` variable. The local override takes highest precedence. 

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
