Systemd
=======

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `systemd` component (part of `_daemon`) within the LibScript ecosystem. This component configures and manages systemd unit files, enabling applications to run as standard background services on compatible Linux distributions.

## Usage
This directory contains the installation and configuration scripts for `systemd`. This component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. 

Furthermore, systemd integrations can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by ensuring system processes are monitored, restarted on failure, and initiated at boot.

## Usage
You can install, start, stop, package, and uninstall systemd using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install systemd

./cli.sh install systemd

./libscript.sh start systemd
./cli.sh start systemd

./libscript.sh stop systemd
./cli.sh stop systemd

./libscript.sh package_as docker systemd
./cli.sh package_as docker systemd

./libscript.sh uninstall systemd
./cli.sh uninstall systemd
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install systemd

:: Local CLI
cli.cmd install systemd

:: Start and Stop
libscript.cmd start systemd
cli.cmd start systemd

libscript.cmd stop systemd
cli.cmd stop systemd

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi systemd
cli.cmd package_as msi systemd

:: Uninstall
libscript.cmd uninstall systemd
cli.cmd uninstall systemd
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `EXEC_START` | Executor | `none` | `` |
| `WORKING_DIR` | Working directory that `EXEC_START` will be run from | `none` | `` |
| `ENV` | Optional additional properties as key/value pairs | `none` | `` |

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
