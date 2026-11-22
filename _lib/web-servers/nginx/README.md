# Nginx

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `nginx` server component
within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the scripts for managing the Nginx component. It works both as a local
version manager (similar to rvm, nvm, pyenv, uv) for precise Nginx version control, and can be
invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open
edX, nextcloud, etc.), serving as a powerful web server layer in multi-tier applications.

You can install, start, stop, package, and uninstall nginx using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install nginx

./cli.sh install nginx

./libscript.sh start nginx
./cli.sh start nginx

./libscript.sh stop nginx
./cli.sh stop nginx

./libscript.sh package-as docker nginx
./cli.sh package-as docker nginx

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
libscript.cmd package-as msi nginx
cli.cmd package-as msi nginx

:: Uninstall
libscript.cmd uninstall nginx
cli.cmd uninstall nginx
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                           | Default           | Aliases/Examples |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------- |
| `NGINX_INSTALL_METHOD`          | How to install NGINX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system`          |                  |
| `NGINX_WWWROOT_NAME`            | The server_name or domain (e.g., example.com) to serve.                                                                                                               | `none`            |                  |
| `NGINX_WWWROOT_PATH`            | The absolute path to the static document root to serve.                                                                                                               | `none`            |                  |
| `NGINX_WWWROOT_LISTEN`          | The HTTP port Nginx should listen on (defaults to 80).                                                                                                                | `80`              |                  |
| `NGINX_SERVERS_ROOT`            | Directory containing per-site Nginx virtual host configuration files.                                                                                                 | `none`            |                  |
| `LIBSCRIPT_LISTEN_PORT_SECURE`  | Global secure port to listen on                                                                                                                                       | `none`            |                  |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                              | `none`            |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                           | `none`            |                  |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                       | `none`            |                  |
| `NGINX_LISTEN_PORT_SECURE`      | Secure port for NGINX to listen on                                                                                                                                    | `none`            |                  |
| `NGINX_LISTEN_PORT`             | Port for NGINX to listen on                                                                                                                                           | `none`            |                  |
| `NGINX_LISTEN_ADDRESS`          | Address for NGINX to listen on                                                                                                                                        | `none`            |                  |
| `NGINX_LISTEN_SOCKET`           | Unix socket for NGINX to listen on                                                                                                                                    | `none`            |                  |
| `NGINX_SERVICE_RUN_AS_USER`     | Windows local user account to run the service (leave empty for Network Service)                                                                                       | `none`            |                  |
| `NGINX_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable)                                                                                                                   | `none`            |                  |
| `NGINX_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations)                                                                                               | `libscript_nginx` |                  |
| `NGINX_HTTPS_ALWAYS`            | Whether to always redirect to HTTPS.                                                                                                                                  | `none`            |                  |
| `NGINX_VARS`                    | Additional variables.                                                                                                                                                 | `none`            |                  |
| `NGINX_LOCATION_EXPR`           | Nginx location expression.                                                                                                                                            | `none`            |                  |
| `NGINX_VERSION`                 | Version of Nginx to install                                                                                                                                           | `latest`          |                  |
| `NGINX_DOWNLOAD_URL`            | Override URL for downloading nginx binary or archive artifacts.                                                                                                       | `none`            |                  |
| `NGINX_FRAGMENT_CONF`           | Configuration variable NGINX_FRAGMENT_CONF for nginx.                                                                                                                 | `none`            |                  |
| `NGINX_LISTEN`                  | Listen endpoint (address:port or socket) for nginx.                                                                                                                   | `none`            |                  |
| `NGINX_PHP_FPM_LISTEN`          | Listen endpoint (address:port or socket) for nginx.                                                                                                                   | `none`            |                  |
| `NGINX_RELEASES_URL`            | Override URL for querying nginx available remote releases.                                                                                                            | `none`            |                  |
| `NGINX_SERVER_NAME`             | Configuration variable NGINX_SERVER_NAME for nginx.                                                                                                                   | `none`            |                  |
| `NGINX_WWWROOT`                 | Configuration variable NGINX_WWWROOT for nginx.                                                                                                                       | `none`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
