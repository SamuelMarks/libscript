Zig
===

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `zig` component (part of `_toolchain`) within the LibScript ecosystem. Zig is a general-purpose programming language and toolchain for maintaining robust, optimal, and reusable software. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation and configuration scripts for `zig`. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for Zig and can be invoked from the global version manager `libscript`. Furthermore, it can be used by libscript as a building block to assemble bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall zig using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install zig

./cli.sh install zig

./libscript.sh start zig
./cli.sh start zig

./libscript.sh stop zig
./cli.sh stop zig

./libscript.sh package_as docker zig
./cli.sh package_as docker zig

./libscript.sh uninstall zig
./cli.sh uninstall zig
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install zig

:: Local CLI
cli.cmd install zig

:: Start and Stop
libscript.cmd start zig
cli.cmd start zig

libscript.cmd stop zig
cli.cmd stop zig

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi zig
cli.cmd package_as msi zig

:: Uninstall
libscript.cmd uninstall zig
cli.cmd uninstall zig
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `ZIG_VERSION` | Specific version of zig to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `ZIG_INSTALL_METHOD` | How to install ZIG. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
