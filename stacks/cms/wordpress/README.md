# WordPress

## Usage

This document describes the `WordPress` component within the LibScript ecosystem. This module
installs WordPress alongside a webserver and MariaDB database.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. Furthermore, this component can be used by libscript to
build bigger stacks (like WordPress, Open edX, nextcloud, etc.) by composing it with caching layers,
load balancers, or other services.

You can manage WordPress using the global `libscript` CLI or local scripts.

- **Install:** `libscript install wordpress`
- **Uninstall:** `libscript uninstall wordpress`
- **Start:** `libscript start wordpress`
- **Stop:** `libscript stop wordpress`
- **Package:** `libscript package-as docker wordpress` (or `msi`, `docker_compose`, etc.)

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                     | Default | Aliases/Examples |
| -------------------------- | ------------------------------- | ------- | ---------------- |
| `WORDPRESS_PHP_FPM_LISTEN` | Variable PHP_FPM_LISTEN.        | `none`  |                  |
| `WORDPRESS_DB_USER`        | Variable WORDPRESS_DB_USER.     | `none`  |                  |
| `WORDPRESS_DB_NAME`        | Variable WORDPRESS_DB_NAME.     | `none`  |                  |
| `WORDPRESS_WEBSERVER`      | Variable WORDPRESS_WEBSERVER.   | `none`  |                  |
| `WORDPRESS_LISTEN`         | Variable WORDPRESS_LISTEN.      | `none`  |                  |
| `WORDPRESS_DB_ENGINE`      | Variable WORDPRESS_DB_ENGINE.   | `none`  |                  |
| `WORDPRESS_VERSION`        | Variable WORDPRESS_VERSION.     | `none`  |                  |
| `WORDPRESS_WWWROOT`        | Variable WWWROOT.               | `none`  |                  |
| `WORDPRESS_DB_PASS`        | Variable WORDPRESS_DB_PASS.     | `none`  |                  |
| `WORDPRESS_SERVER_NAME`    | Variable WORDPRESS_SERVER_NAME. | `none`  |                  |

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
- `_lib/databases/mariadb`: MariaDB database server
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): HTTP web server and SSL termination
