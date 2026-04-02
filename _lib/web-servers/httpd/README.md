Apache HTTPD
============

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `httpd` server component within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the scripts for managing the Apache HTTPD component. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for precise HTTPD version control, and can be invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.), serving as a reliable web server foundation.

## Usage
You can install, start, stop, package, and uninstall httpd using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install httpd

./cli.sh install httpd

./libscript.sh start httpd
./cli.sh start httpd

./libscript.sh stop httpd
./cli.sh stop httpd

./libscript.sh package_as docker httpd
./cli.sh package_as docker httpd

./libscript.sh uninstall httpd
./cli.sh uninstall httpd
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install httpd

:: Local CLI
cli.cmd install httpd

:: Start and Stop
libscript.cmd start httpd
cli.cmd start httpd

libscript.cmd stop httpd
cli.cmd stop httpd

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi httpd
cli.cmd package_as msi httpd

:: Uninstall
libscript.cmd uninstall httpd
cli.cmd uninstall httpd
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

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
