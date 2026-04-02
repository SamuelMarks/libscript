Caddy
=====

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `caddy` server component within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the scripts for managing the Caddy component. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for precise Caddy version control, and can be invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.), easily providing automatic HTTPS and web server functionality.

## Usage
You can manage the lifecycle of this component using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install caddy

./cli.sh install caddy

./libscript.sh start caddy
./cli.sh start caddy

./libscript.sh stop caddy
./cli.sh stop caddy

./libscript.sh package_as docker caddy
./cli.sh package_as docker caddy

./libscript.sh uninstall caddy
./cli.sh uninstall caddy
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install caddy

:: Local CLI
cli.cmd install caddy

:: Start and Stop
libscript.cmd start caddy
cli.cmd start caddy

libscript.cmd stop caddy
cli.cmd stop caddy

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi caddy
cli.cmd package_as msi caddy

:: Uninstall
libscript.cmd uninstall caddy
cli.cmd uninstall caddy
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `CADDY_VERSION` | Specific version of caddy to install. Can be a numeric version or an alias. | `latest` | `latest, stable` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `CADDY_INSTALL_METHOD` | How to install CADDY. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `CADDY_LISTEN_PORT` | Port for CADDY to listen on | `none` | `` |
| `CADDY_LISTEN_ADDRESS` | Address for CADDY to listen on | `none` | `` |
| `CADDY_LISTEN_SOCKET` | Unix socket for CADDY to listen on | `none` | `` |

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
