C
=

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `c` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is C?**: C is a powerful, general-purpose procedural computer programming language supporting structured programming, lexical variable scope, and recursion, widely used for system programming and embedded systems.

## Usage
This directory contains the installation and configuration scripts for `c`. 

### Local and Global Version Management

The `c` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`. This dual capability allows developers to manage specific versions per project locally or enforce system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build, deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can orchestrate `c` toolchains alongside databases, web servers, and other services to form a cohesive, reproducible stack.

## Usage
You can install, start, stop, package, and uninstall c using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install c

./cli.sh install c

./libscript.sh start c
./cli.sh start c

./libscript.sh stop c
./cli.sh stop c

./libscript.sh package_as docker c
./cli.sh package_as docker c

./libscript.sh uninstall c
./cli.sh uninstall c
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install c

:: Local CLI
cli.cmd install c

:: Start and Stop
libscript.cmd start c
cli.cmd start c

libscript.cmd stop c
cli.cmd stop c

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi c
cli.cmd package_as msi c

:: Uninstall
libscript.cmd uninstall c
cli.cmd uninstall c
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `C_INSTALL_METHOD` | How to install C. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
