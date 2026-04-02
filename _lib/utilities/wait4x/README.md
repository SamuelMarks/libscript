Wait4X
======

## Purpose & Overview
**Purpose**: This document provides context and technical details for the `wait4x` component (part of `_toolchain`) within the LibScript ecosystem. `wait4x` is a command-line tool that allows you to wait for various ports and services (like databases, HTTP servers, or generic TCP sockets) to become available, making it invaluable for reliable CI/CD and orchestration flows.

Crucially, this module allows `wait4x` to function both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global version manager, `libscript`. Furthermore, `libscript` can utilize this `wait4x` toolchain as a foundational building block to provision and orchestrate much larger, complex software stacks (such as WordPress, Open edX, Nextcloud, and more) where service startup synchronization is required.

## Usage with LibScript
This directory contains the installation and configuration scripts for `wait4x`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

## Usage
You can install, start, stop, package, and uninstall wait4x using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install wait4x

./cli.sh install wait4x

./libscript.sh start wait4x
./cli.sh start wait4x

./libscript.sh stop wait4x
./cli.sh stop wait4x

./libscript.sh package_as docker wait4x
./cli.sh package_as docker wait4x

./libscript.sh uninstall wait4x
./cli.sh uninstall wait4x
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install wait4x

:: Local CLI
cli.cmd install wait4x

:: Start and Stop
libscript.cmd start wait4x
cli.cmd start wait4x

libscript.cmd stop wait4x
cli.cmd stop wait4x

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi wait4x
cli.cmd package_as msi wait4x

:: Uninstall
libscript.cmd uninstall wait4x
cli.cmd uninstall wait4x
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `WAIT4X_INSTALL_METHOD` | How to install WAIT4X. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
