Common
======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `_common` component (part of `_lib`) within the LibScript ecosystem. This component provides shared utilities, core functions, and baseline scripts that are universally utilized by other modules across the LibScript framework to ensure consistent execution across different platforms.

## Usage
This directory contains the essential shared scripts for `_common`. It is designed to work both as a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for managing common toolkit versions, and can be seamlessly invoked from the global version manager `libscript`.

Furthermore, these common utilities are foundational and can be used by LibScript to build and provision bigger stacks, such as WordPress, Open edX, Nextcloud, and other enterprise-grade application deployments.

## Usage
You can install, start, stop, package, and uninstall _common using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install _common

./cli.sh install _common

./libscript.sh start _common
./cli.sh start _common

./libscript.sh stop _common
./cli.sh stop _common

./libscript.sh package_as docker _common
./cli.sh package_as docker _common

./libscript.sh uninstall _common
./cli.sh uninstall _common
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install _common

:: Local CLI
cli.cmd install _common

:: Start and Stop
libscript.cmd start _common
cli.cmd start _common

libscript.cmd stop _common
cli.cmd stop _common

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi _common
cli.cmd package_as msi _common

:: Uninstall
libscript.cmd uninstall _common
cli.cmd uninstall _common
```

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Platform Support
- Linux
- macOS
- Windows
