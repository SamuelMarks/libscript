Cc
==

## Purpose & Overview
**Purpose**: This document provides context and technical details for the `cc` component (part of `_toolchain`) within the LibScript ecosystem. This component manages the installation of standard C/C++ compiler toolchains (such as GCC or Clang), which are essential for compiling and linking C and C++ programs.

Crucially, this module allows `cc` to function both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global version manager, `libscript`. Furthermore, `libscript` can utilize this `cc` toolchain as a foundational building block to provision and orchestrate much larger, complex software stacks (such as WordPress, Open edX, Nextcloud, and more).

## Usage with LibScript
This directory contains the installation and configuration scripts for `cc`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

## Usage
You can install, start, stop, package, and uninstall cc using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install cc

./cli.sh install cc

./libscript.sh start cc
./cli.sh start cc

./libscript.sh stop cc
./cli.sh stop cc

./libscript.sh package_as docker cc
./cli.sh package_as docker cc

./libscript.sh uninstall cc
./cli.sh uninstall cc
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install cc

:: Local CLI
cli.cmd install cc

:: Start and Stop
libscript.cmd start cc
cli.cmd start cc

libscript.cmd stop cc
cli.cmd stop cc

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi cc
cli.cmd package_as msi cc

:: Uninstall
libscript.cmd uninstall cc
cli.cmd uninstall cc
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `CC_INSTALL_METHOD` | How to install CC. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
