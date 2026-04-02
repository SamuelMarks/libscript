Nginx
=====

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `nginx` server component within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage
This directory contains the scripts for managing the Nginx component. It works both as a local version manager (similar to rvm, nvm, pyenv, uv) for precise Nginx version control, and can be invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open edX, nextcloud, etc.), serving as a powerful web server layer in multi-tier applications.

## Usage
You can install, start, stop, package, and uninstall nginx using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install nginx

./cli.sh install nginx

./libscript.sh start nginx
./cli.sh start nginx

./libscript.sh stop nginx
./cli.sh stop nginx

./libscript.sh package_as docker nginx
./cli.sh package_as docker nginx

./libscript.sh uninstall nginx
./cli.sh uninstall nginx
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install nginx

:: Local CLI
cli.cmd install nginx

:: Start and Stop
libscript.cmd start nginx
cli.cmd start nginx

libscript.cmd stop nginx
cli.cmd stop nginx

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi nginx
cli.cmd package_as msi nginx

:: Uninstall
libscript.cmd uninstall nginx
cli.cmd uninstall nginx
```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `NGINX_INSTALL_METHOD` | How to install Nginx. | `system` | `` |
| `WWWROOT_NAME` | The server name/domain (e.g. example.com) | `none` | `` |
| `WWWROOT_PATH` | The path to the document root | `none` | `` |
| `WWWROOT_LISTEN` | The port Nginx should listen on | `80` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `LIBSCRIPT_LISTEN_PORT_SECURE` | Global secure port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `NGINX_LISTEN_PORT_SECURE` | Secure port for NGINX to listen on | `none` | `` |
| `NGINX_LISTEN_PORT` | Port for NGINX to listen on | `none` | `` |
| `NGINX_LISTEN_ADDRESS` | Address for NGINX to listen on | `none` | `` |
| `NGINX_LISTEN_SOCKET` | Unix socket for NGINX to listen on | `none` | `` |
| `NGINX_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` | `` |
| `NGINX_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` | `` |
| `NGINX_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_nginx` | `` |

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
