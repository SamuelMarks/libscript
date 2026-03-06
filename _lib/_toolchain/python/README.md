# Python (Toolchain)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `python` component (part of `_toolchain`) within the LibScript ecosystem. Python is a high-level, interpreted programming language known for its readability, dynamic typing, and comprehensive standard library, widely used in web development, data science, and scripting. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation and configuration scripts for `python`. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for Python and can be invoked from the global version manager `libscript`. Furthermore, it can be used by libscript as a building block to assemble bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

### Usage with LibScript

You can manage the lifecycle of Python using the `libscript` CLI. 

**Install / Uninstall / Start / Stop / Package:**

```sh
# Install Python
./libscript.sh install python [VERSION] [OPTIONS]

# Uninstall Python
./libscript.sh uninstall python

# Start Python (if applicable as a daemon/background process)
./libscript.sh start python

# Stop Python (if applicable)
./libscript.sh stop python

# Package Python
./libscript.sh package_as docker python
```
*(On Windows, use `libscript.cmd` or `libscript.bat` instead of `./libscript.sh`)*

You can also run the local `cli.sh` or `cli.cmd` directly within this directory for component-level operations.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `PYTHON_VERSION` | Version of Python demanded. Can be a specific numeric version number or an alias | `3.11` | `latest, cpython` |
| `VENV` | Path to a Python virtualenv (will create if nonexistent) | `none` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `PYTHON_INSTALL_METHOD` | How to install PYTHON. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
