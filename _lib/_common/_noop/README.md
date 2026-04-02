Noop
====

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `_noop` component (part of `_common`) within the LibScript ecosystem. This module serves as a "no-operation" (noop) placeholder or dummy component. It is primarily used for testing, structural padding, or safely bypassing execution paths where a component is required but no actual operation should be performed.

## Usage
This directory contains the configuration scripts for `_noop`. Despite being a dummy component, it is designed to strictly follow the standard LibScript architecture. It works both as a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager `libscript`.

Additionally, the `_noop` module can be utilized by LibScript when dynamically assembling and building bigger stacks (like WordPress, Open edX, Nextcloud), acting as a safe fallback when specific dependencies are disabled or intentionally omitted from a stack deployment.

## Usage
You can install, start, stop, package, and uninstall _noop using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install _noop

./cli.sh install _noop

./libscript.sh start _noop
./cli.sh start _noop

./libscript.sh stop _noop
./cli.sh stop _noop

./libscript.sh package_as docker _noop
./cli.sh package_as docker _noop

./libscript.sh uninstall _noop
./cli.sh uninstall _noop
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install _noop

:: Local CLI
cli.cmd install _noop

:: Start and Stop
libscript.cmd start _noop
cli.cmd start _noop

libscript.cmd stop _noop
cli.cmd stop _noop

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi _noop
cli.cmd package_as msi _noop

:: Uninstall
libscript.cmd uninstall _noop
cli.cmd uninstall _noop
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
