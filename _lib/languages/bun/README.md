Bun
===

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `bun` component (part of `_toolchain`) within the LibScript ecosystem. This component is responsible for installing and managing **Bun**, the fast all-in-one JavaScript runtime, bundler, transpiler, and package manager.

## Usage
This directory contains the installation and configuration scripts for `bun`. It is engineered to operate both as a robust local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for localized Bun environment management, and can be invoked seamlessly from the global version manager `libscript`.

By leveraging this component, LibScript can use Bun as a high-performance building block to provision and orchestrate much bigger stacks, such as WordPress, Open edX, Nextcloud, and modern JavaScript-heavy web applications.

## Usage
You can install, start, stop, package, and uninstall bun using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install bun

./cli.sh install bun

./libscript.sh start bun
./cli.sh start bun

./libscript.sh stop bun
./cli.sh stop bun

./libscript.sh package_as docker bun
./cli.sh package_as docker bun

./libscript.sh uninstall bun
./cli.sh uninstall bun
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install bun

:: Local CLI
cli.cmd install bun

:: Start and Stop
libscript.cmd start bun
cli.cmd start bun

libscript.cmd stop bun
cli.cmd stop bun

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi bun
cli.cmd package_as msi bun

:: Uninstall
libscript.cmd uninstall bun
cli.cmd uninstall bun
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `BUN_VERSION` | Version of Bun demanded. Can be a specific version number like 'bun-v1.1.0' or an alias. | `latest` | `latest, canary` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `BUN_INSTALL_METHOD` | How to install BUN. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
