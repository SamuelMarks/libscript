# Rabbitmq (Storage/Database)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `rabbitmq` component (part of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres 18, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Recent advancements have stabilized major Windows installer generation (MSI, InnoSetup, NSIS) and expanded macOS native service provisioning.

## Overview

This directory contains the installation, configuration, and lifecycle management scripts for **RabbitMQ**. 

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) for managing isolated instances of RabbitMQ, and it can be invoked seamlessly from the **global version manager**, `libscript`. 

Furthermore, `libscript` can utilize this RabbitMQ component as a foundational building block to provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

### Lifecycle Management (Install, Start, Stop, Package, Uninstall)

You can install, start, stop, package, and uninstall RabbitMQ using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh
# Install
libscript install rabbitmq [VERSION] [OPTIONS]

# Start and Stop
libscript start rabbitmq
libscript stop rabbitmq

# Package (e.g., as Docker image)
libscript package_as docker rabbitmq

# Uninstall
libscript uninstall rabbitmq
```

**Windows:**
```cmd
:: Install
libscript.cmd install rabbitmq [VERSION] [OPTIONS]

:: Start and Stop
libscript.cmd start rabbitmq
libscript.cmd stop rabbitmq

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi rabbitmq

:: Uninstall
libscript.cmd uninstall rabbitmq
```

*Alternatively, you can execute these locally from within this directory using `./cli.sh <COMMAND> rabbitmq` or `cli.cmd <COMMAND> rabbitmq`.*



## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

