Rust
====

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `rust` component (part of `_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is Rust?**: Rust is a multi-paradigm, general-purpose programming language that emphasizes performance, type safety, and concurrency, with a strict borrow checker ensuring memory safety without a garbage collector.

## Usage
This directory contains the installation and configuration scripts for `rust`. 

### Local and Global Version Management

The `rust` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`. This dual capability allows developers to manage specific versions per project locally or enforce system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build, deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can orchestrate `rust` alongside databases, web servers, and other services to form a cohesive, reproducible stack.

## Usage
You can install, start, stop, package, and uninstall rust using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install rust

./cli.sh install rust

./libscript.sh start rust
./cli.sh start rust

./libscript.sh stop rust
./cli.sh stop rust

./libscript.sh package_as docker rust
./cli.sh package_as docker rust

./libscript.sh uninstall rust
./cli.sh uninstall rust
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install rust

:: Local CLI
cli.cmd install rust

:: Start and Stop
libscript.cmd start rust
cli.cmd start rust

libscript.cmd stop rust
cli.cmd stop rust

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi rust
cli.cmd package_as msi rust

:: Uninstall
libscript.cmd uninstall rust
cli.cmd uninstall rust
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `RUST_VERSION` | Version of Rust demanded. Can be "nightly"|"beta"|"stable" xor a specific version | `stable` | `stable, beta, nightly` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `RUST_INSTALL_METHOD` | How to install RUST. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

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
