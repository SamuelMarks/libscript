Git Servers
===========

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `_git` component (part of `_lib`) within the LibScript ecosystem. This component is responsible for installing, managing, and configuring **Git**, the widely used distributed version control system. It provides the necessary scripts to provision Git across supported operating systems efficiently.

## Usage
This directory contains the scripts for managing Git. It is designed to work both as a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for isolated project-level Git installations, and can also be seamlessly invoked from the global version manager `libscript`.

Additionally, this component can be utilized by LibScript as a foundational dependency to build and provision bigger stacks, such as WordPress, Open edX, Nextcloud, and other complex software environments.

## Usage
You can install, start, stop, package, and uninstall git-servers using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install git-servers

./cli.sh install git-servers

./libscript.sh start git-servers
./cli.sh start git-servers

./libscript.sh stop git-servers
./cli.sh stop git-servers

./libscript.sh package_as docker git-servers
./cli.sh package_as docker git-servers

./libscript.sh uninstall git-servers
./cli.sh uninstall git-servers
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install git-servers

:: Local CLI
cli.cmd install git-servers

:: Start and Stop
libscript.cmd start git-servers
cli.cmd start git-servers

libscript.cmd stop git-servers
cli.cmd stop git-servers

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi git-servers
cli.cmd package_as msi git-servers

:: Uninstall
libscript.cmd uninstall git-servers
cli.cmd uninstall git-servers
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `1` | repository | `none` | `` |
| `2` | target directory | `none` | `` |
| `3` | branch | `none` | `` |

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Platform Support
- Linux
- macOS
- Windows
