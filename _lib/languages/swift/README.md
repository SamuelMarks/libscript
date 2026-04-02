Swift
=====

## Purpose & Overview
**Purpose**: This document provides context and technical details for the `swift` component (part of `_toolchain`) within the LibScript ecosystem. This component manages the installation of the Swift programming language toolchain, enabling you to build applications for macOS, iOS, Linux, and Windows.

Crucially, this module allows `swift` to function both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global version manager, `libscript`. Furthermore, `libscript` can utilize this `swift` toolchain as a foundational building block to provision and orchestrate much larger, complex software stacks (such as WordPress, Open edX, Nextcloud, and more).

## Usage with LibScript
This directory contains the installation and configuration scripts for `swift`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

## Usage
You can install, start, stop, package, and uninstall swift using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install swift

./cli.sh install swift

./libscript.sh start swift
./cli.sh start swift

./libscript.sh stop swift
./cli.sh stop swift

./libscript.sh package_as docker swift
./cli.sh package_as docker swift

./libscript.sh uninstall swift
./cli.sh uninstall swift
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install swift

:: Local CLI
cli.cmd install swift

:: Start and Stop
libscript.cmd start swift
cli.cmd start swift

libscript.cmd stop swift
cli.cmd stop swift

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi swift
cli.cmd package_as msi swift

:: Uninstall
libscript.cmd uninstall swift
cli.cmd uninstall swift
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `SWIFT_INSTALL_METHOD` | How to install SWIFT. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
