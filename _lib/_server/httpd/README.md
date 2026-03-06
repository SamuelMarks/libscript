# Apache HTTPD (Server)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `httpd` server component within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview & Usage

This directory contains the scripts for managing the Apache HTTPD component. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for precise HTTPD version control, and can be invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.), serving as a reliable web server foundation.

### Lifecycle Commands

You can manage the lifecycle of this component using `libscript`:

- **Install:** `libscript install httpd`
- **Start:** `libscript start httpd`
- **Stop:** `libscript stop httpd`
- **Uninstall:** `libscript uninstall httpd`
- **Package:** `libscript package_as docker httpd` (or other formats like `docker_compose`, `msi`, etc.)

Alternatively, you can interact with it locally:

**Unix (Linux/macOS):**
```sh
./cli.sh <COMMAND> httpd [VERSION] [OPTIONS]
```

**Windows:**
```cmd
cli.cmd <COMMAND> httpd [VERSION] [OPTIONS]
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `HTTPD_VERSION` | Specific version of httpd to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `HTTPD_INSTALL_METHOD` | How to install HTTPD. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `HTTPD_LISTEN_PORT` | Port for HTTPD to listen on | `none` | `` |
| `HTTPD_LISTEN_ADDRESS` | Address for HTTPD to listen on | `none` | `` |
| `HTTPD_LISTEN_SOCKET` | Unix socket for HTTPD to listen on | `none` | `` |

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.