# Nextcloud

## Usage

This document describes the `Nextcloud` component within the LibScript ecosystem. This module
installs Nextcloud alongside a webserver and MariaDB database.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. Furthermore, this component can be used by libscript to
build bigger stacks (like Nextcloud, Open edX, nextcloud, etc.) by composing it with caching layers,
load balancers, or other services.

You can manage Nextcloud using the global `libscript` CLI or local scripts.

- **Install:** `libscript install nextcloud`
- **Uninstall:** `libscript uninstall nextcloud`
- **Start:** `libscript start nextcloud`
- **Stop:** `libscript stop nextcloud`
- **Package:** `libscript package-as docker nextcloud` (or `msi`, `docker_compose`, etc.)

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                        | Default | Aliases/Examples |
| -------------------------- | ---------------------------------------------------------------------------------- | ------- | ---------------- |
| `NEXTCLOUD_VERSION`        | Target Nextcloud server release version or alias (e.g., latest) to deploy.         | `none`  |                  |
| `NEXTCLOUD_PHP_FPM_LISTEN` | PHP-FPM FastCGI socket path or host:port endpoint executing Nextcloud PHP workers. | `none`  |                  |
| `NEXTCLOUD_SERVER_NAME`    | Trusted domain and virtual host server_name configured for Nextcloud.              | `none`  |                  |
| `NEXTCLOUD_DB_PASS`        | Password authenticating the Nextcloud database user.                               | `none`  |                  |
| `NEXTCLOUD_DB_USER`        | Database username used by Nextcloud to connect to its backing store.               | `none`  |                  |
| `NEXTCLOUD_WWWROOT`        | Filesystem webroot directory containing the Nextcloud server installation.         | `none`  |                  |
| `NEXTCLOUD_DB_NAME`        | Database schema name storing Nextcloud metadata, shares, and user accounts.        | `none`  |                  |
| `NEXTCLOUD_DB_TYPE`        | Database driver backend for Nextcloud (e.g., pgsql, mysql, sqlite).                | `none`  |                  |
| `NEXTCLOUD_WEBSERVER`      | Frontend web server component fronting Nextcloud (e.g., nginx, caddy, httpd).      | `none`  |                  |
| `NEXTCLOUD_LISTEN`         | HTTP bind address:port or UNIX socket exposed by the Nextcloud web server.         | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/php`: PHP runtime and PHP-FPM processor
- `_lib/databases/mariadb` (or `postgres`, `sqlite`): Database storage layer
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): HTTP web server and TLS terminator
- `_lib/caches/redis`: In-memory transactional file locking and caching layer
