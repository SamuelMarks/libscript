Python
======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `python` component (part of `_toolchain`) within the LibScript ecosystem. Python is a high-level, interpreted programming language known for its readability, dynamic typing, and comprehensive standard library, widely used in web development, data science, and scripting. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation and configuration scripts for `python`. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for Python and can be invoked from the global version manager `libscript`. Furthermore, it can be used by libscript as a building block to assemble bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall python using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install python

./cli.sh install python

./libscript.sh start python
./cli.sh start python

./libscript.sh stop python
./cli.sh stop python

./libscript.sh package_as docker python
./cli.sh package_as docker python

./libscript.sh uninstall python
./cli.sh uninstall python
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install python

:: Local CLI
cli.cmd install python

:: Start and Stop
libscript.cmd start python
cli.cmd start python

libscript.cmd stop python
cli.cmd stop python

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi python
cli.cmd package_as msi python

:: Uninstall
libscript.cmd uninstall python
cli.cmd uninstall python
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `PYTHON_VERSION` | Version of Python demanded. Can be a specific numeric version number or an alias | `3.11` | `latest, cpython` |
| `VENV` | Path to a Python virtualenv (will create if nonexistent) | `none` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `PYTHON_INSTALL_METHOD` | How to install PYTHON. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
