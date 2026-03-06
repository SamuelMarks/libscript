# Bun (Toolchain)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `bun` component (part of `_toolchain`) within the LibScript ecosystem. This component is responsible for installing and managing **Bun**, the fast all-in-one JavaScript runtime, bundler, transpiler, and package manager.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `bun`. It is engineered to operate both as a robust local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for localized Bun environment management, and can be invoked seamlessly from the global version manager `libscript`.

By leveraging this component, LibScript can use Bun as a high-performance building block to provision and orchestrate much bigger stacks, such as WordPress, Open edX, Nextcloud, and modern JavaScript-heavy web applications.

### Lifecycle Commands

You can manage the full lifecycle of Bun (install, uninstall, start, stop, package) via the global router or directly via the component's CLI.

**Unix (Linux/macOS):**
```sh
# Install
./cli.sh install bun [VERSION] [OPTIONS]
./libscript.sh install bun

# Uninstall
./cli.sh uninstall bun
./libscript.sh uninstall bun

# Start / Stop (if running a Bun server daemon)
./cli.sh start bun
./cli.sh stop bun

# Package
./cli.sh package_as docker bun
```

**Windows:**
```cmd
# Install
cli.cmd install bun [VERSION] [OPTIONS]
libscript.cmd install bun

# Uninstall
cli.cmd uninstall bun
libscript.cmd uninstall bun

# Start / Stop
cli.cmd start bun
cli.cmd stop bun

# Package
cli.cmd package_as msi bun
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
