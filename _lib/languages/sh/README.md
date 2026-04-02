Sh
==

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `sh` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is Shell Scripting (Sh)?**: Shell scripting (Sh) refers to a computer program designed to be run by the Unix shell, a command-line interpreter. It is widely used for system administration, task automation, and file manipulation.

## Usage
This directory contains the installation and configuration scripts for `sh`. 

### Local and Global Version Management

The `sh` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`. This dual capability allows developers to manage specific versions per project locally or enforce system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build, deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can orchestrate `sh` alongside databases, web servers, and other services to form a cohesive, reproducible stack.

## Usage
You can install, start, stop, package, and uninstall sh using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install sh

./cli.sh install sh

./libscript.sh start sh
./cli.sh start sh

./libscript.sh stop sh
./cli.sh stop sh

./libscript.sh package_as docker sh
./cli.sh package_as docker sh

./libscript.sh uninstall sh
./cli.sh uninstall sh
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install sh

:: Local CLI
cli.cmd install sh

:: Start and Stop
libscript.cmd start sh
cli.cmd start sh

libscript.cmd stop sh
cli.cmd stop sh

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi sh
cli.cmd package_as msi sh

:: Uninstall
libscript.cmd uninstall sh
cli.cmd uninstall sh
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `SH_INSTALL_METHOD` | How to install SH. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
