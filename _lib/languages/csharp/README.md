C#
==

## Purpose & Overview
**Purpose**: This document provides context and technical details for the `csharp` component (part of `_toolchain`) within the LibScript ecosystem. This component manages the installation of the C# and .NET platform toolchain, providing the necessary SDKs and runtimes to build and execute .NET applications.

Crucially, this module allows `csharp` to function both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global version manager, `libscript`. Furthermore, `libscript` can utilize this `csharp` toolchain as a foundational building block to provision and orchestrate much larger, complex software stacks (such as WordPress, Open edX, Nextcloud, and more).

## Usage with LibScript
This directory contains the installation and configuration scripts for `csharp`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

## Usage
You can install, start, stop, package, and uninstall csharp using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install csharp

./cli.sh install csharp

./libscript.sh start csharp
./cli.sh start csharp

./libscript.sh stop csharp
./cli.sh stop csharp

./libscript.sh package_as docker csharp
./cli.sh package_as docker csharp

./libscript.sh uninstall csharp
./cli.sh uninstall csharp
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install csharp

:: Local CLI
cli.cmd install csharp

:: Start and Stop
libscript.cmd start csharp
cli.cmd start csharp

libscript.cmd stop csharp
cli.cmd stop csharp

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi csharp
cli.cmd package_as msi csharp

:: Uninstall
libscript.cmd uninstall csharp
cli.cmd uninstall csharp
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `CSHARP_INSTALL_METHOD` | How to install CSHARP. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
