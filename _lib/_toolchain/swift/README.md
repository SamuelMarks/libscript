# Swift (Toolchain)

## Purpose & Overview

**Purpose**: This document provides context and technical details for the `swift` component (part of `_toolchain`) within the LibScript ecosystem. This component manages the installation of the Swift programming language toolchain, enabling you to build applications for macOS, iOS, Linux, and Windows.

Crucially, this module allows `swift` to function both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global version manager, `libscript`. Furthermore, `libscript` can utilize this `swift` toolchain as a foundational building block to provision and orchestrate much larger, complex software stacks (such as WordPress, Open edX, Nextcloud, and more).

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Usage with LibScript

This directory contains the installation and configuration scripts for `swift`. It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle Commands

You can install, uninstall, start, stop, and package `swift` using the following standard LibScript commands:

**Unix (Linux/macOS):**
```sh
# Install a specific version
./libscript.sh install swift [VERSION] [OPTIONS]

# Start/Stop the service (if applicable/running as daemon)
./libscript.sh start swift
./libscript.sh stop swift

# Package the component (e.g., into a Docker image or installer)
./libscript.sh package_as docker swift

# Uninstall the component
./libscript.sh uninstall swift
```

**Windows:**
```cmd
# Install a specific version
libscript.cmd install swift [VERSION] [OPTIONS]

# Start/Stop the service (if applicable/running as daemon)
libscript.cmd start swift
libscript.cmd stop swift

# Package the component (e.g., into an MSI or Docker image)
libscript.cmd package_as msi swift

# Uninstall the component
libscript.cmd uninstall swift
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
