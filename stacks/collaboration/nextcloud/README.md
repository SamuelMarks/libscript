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

| Variable                   | Description                     | Default | Aliases/Examples |
| -------------------------- | ------------------------------- | ------- | ---------------- |
| `NEXTCLOUD_VERSION`        | Variable NEXTCLOUD_VERSION.     | `none`  |                  |
| `NEXTCLOUD_PHP_FPM_LISTEN` | Variable PHP_FPM_LISTEN.        | `none`  |                  |
| `NEXTCLOUD_SERVER_NAME`    | Variable NEXTCLOUD_SERVER_NAME. | `none`  |                  |
| `NEXTCLOUD_DB_PASS`        | Variable NEXTCLOUD_DB_PASS.     | `none`  |                  |
| `NEXTCLOUD_DB_USER`        | Variable NEXTCLOUD_DB_USER.     | `none`  |                  |
| `NEXTCLOUD_WWWROOT`        | Variable WWWROOT.               | `none`  |                  |
| `NEXTCLOUD_DB_NAME`        | Variable NEXTCLOUD_DB_NAME.     | `none`  |                  |
| `NEXTCLOUD_DB_TYPE`        | Variable NEXTCLOUD_DB_TYPE.     | `none`  |                  |
| `NEXTCLOUD_WEBSERVER`      | Variable NEXTCLOUD_WEBSERVER.   | `none`  |                  |
| `NEXTCLOUD_LISTEN`         | Variable NEXTCLOUD_LISTEN.      | `none`  |                  |

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
