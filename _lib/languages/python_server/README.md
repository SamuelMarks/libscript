Python Server
=============

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `python` server component within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the scripts for managing the Python server component. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for precise Python version control, and can be invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.), serving as a robust foundation for multi-tier architectures.

## Usage
You can install, start, stop, package, and uninstall python_server using the global `libscript` command or the local CLI.

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
| `DEST` | Destination (working directory) | `none` | `` |
| `VARS` | Key/value in JSON format (as an escaped string) | `none` | `` |
| `VENV` | Path to a Python virtualenv | `none` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `PYTHON_LISTEN_PORT` | Port for PYTHON to listen on | `none` | `` |
| `PYTHON_LISTEN_ADDRESS` | Address for PYTHON to listen on | `none` | `` |
| `PYTHON_LISTEN_SOCKET` | Unix socket for PYTHON to listen on | `none` | `` |

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
