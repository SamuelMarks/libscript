# Python (Server)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `python` server component within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support, servers, and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview & Usage

This directory contains the scripts for managing the Python server component. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for precise Python version control, and can be invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.), serving as a robust foundation for multi-tier architectures.

### Lifecycle Commands

You can manage the lifecycle of this component using `libscript`:

- **Install:** `libscript install python`
- **Start:** `libscript start python`
- **Stop:** `libscript stop python`
- **Uninstall:** `libscript uninstall python`
- **Package:** `libscript package_as docker python` (or other formats like `docker_compose`, `msi`, etc.)

Alternatively, you can interact with it locally:

**Unix (Linux/macOS):**
```sh
./cli.sh <COMMAND> python [VERSION] [OPTIONS]
```

**Windows:**
```cmd
cli.cmd <COMMAND> python [VERSION] [OPTIONS]
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `DEST` | Destination (working directory) | `none` | `` |
| `VARS` | Key/value in JSON format (as an escaped string) | `none` | `` |
| `VENV` | Path to a Python virtualenv | `none` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `PYTHON_LISTEN_PORT` | Port for PYTHON to listen on | `none` | `` |
| `PYTHON_LISTEN_ADDRESS` | Address for PYTHON to listen on | `none` | `` |
| `PYTHON_LISTEN_SOCKET` | Unix socket for PYTHON to listen on | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
## Variables

See `vars.schema.json` for details on available variables.
