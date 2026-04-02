Kotlin
======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `kotlin` component (part of `_toolchain`) within the LibScript ecosystem. Kotlin is a modern, cross-platform, statically typed programming language designed to interoperate fully with Java, while providing more concise and safer syntax. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation and configuration scripts for `kotlin`. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for Kotlin and can be invoked from the global version manager `libscript`. Furthermore, it can be used by libscript as a building block to assemble bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall kotlin using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install kotlin

./cli.sh install kotlin

./libscript.sh start kotlin
./cli.sh start kotlin

./libscript.sh stop kotlin
./cli.sh stop kotlin

./libscript.sh package_as docker kotlin
./cli.sh package_as docker kotlin

./libscript.sh uninstall kotlin
./cli.sh uninstall kotlin
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install kotlin

:: Local CLI
cli.cmd install kotlin

:: Start and Stop
libscript.cmd start kotlin
cli.cmd start kotlin

libscript.cmd stop kotlin
cli.cmd stop kotlin

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi kotlin
cli.cmd package_as msi kotlin

:: Uninstall
libscript.cmd uninstall kotlin
cli.cmd uninstall kotlin
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `KOTLIN_INSTALL_METHOD` | How to install KOTLIN. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
