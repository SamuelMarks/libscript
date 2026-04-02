Elixir
======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `elixir` component (part of `_toolchain`) within the LibScript ecosystem. Elixir is a dynamic, functional language designed for building scalable and maintainable applications, running on the Erlang VM (BEAM). LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation and configuration scripts for `elixir`. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for Elixir and can be invoked from the global version manager `libscript`. Furthermore, it can be used by libscript as a building block to assemble bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall elixir using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install elixir

./cli.sh install elixir

./libscript.sh start elixir
./cli.sh start elixir

./libscript.sh stop elixir
./cli.sh stop elixir

./libscript.sh package_as docker elixir
./cli.sh package_as docker elixir

./libscript.sh uninstall elixir
./cli.sh uninstall elixir
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install elixir

:: Local CLI
cli.cmd install elixir

:: Start and Stop
libscript.cmd start elixir
cli.cmd start elixir

libscript.cmd stop elixir
cli.cmd stop elixir

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi elixir
cli.cmd package_as msi elixir

:: Uninstall
libscript.cmd uninstall elixir
cli.cmd uninstall elixir
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `ELIXIR_VERSION` | Specific version of elixir to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `ELIXIR_INSTALL_METHOD` | How to install ELIXIR. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
