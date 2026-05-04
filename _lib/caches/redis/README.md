# Redis

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `redis` component (part of `_caches`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the installation, configuration, and lifecycle management scripts for **Redis**. 

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`, `nvm`, `pyenv`, or `uv`) for managing isolated instances of Redis, and it can be invoked seamlessly from the **global version manager**, `libscript`. 

Furthermore, `libscript` can utilize this Redis component as a foundational building block to provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

You can install, start, stop, package, and uninstall redis using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh
./libscript.sh install redis 
./cli.sh install redis 

./libscript.sh start redis
./cli.sh start redis

./libscript.sh stop redis
./cli.sh stop redis

./libscript.sh package_as docker redis
./cli.sh package_as docker redis

./libscript.sh uninstall redis
./cli.sh uninstall redis
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install redis 

:: Local CLI
cli.cmd install redis 

:: Start and Stop
libscript.cmd start redis
cli.cmd start redis

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi redis
cli.cmd package_as msi redis

:: Uninstall
libscript.cmd uninstall redis
cli.cmd uninstall redis
```

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options
See `vars.schema.json` for all available configuration options.

## Platform Support
- Linux
- macOS
- Windows
