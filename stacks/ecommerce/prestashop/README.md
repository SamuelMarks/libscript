# Prestashop

This module automates the setup of PrestaShop.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                      | Default | Aliases/Examples |
| --------------------------- | -------------------------------- | ------- | ---------------- |
| `PRESTASHOP_PHP_FPM_LISTEN` | Variable PHP_FPM_LISTEN.         | `none`  |                  |
| `PRESTASHOP_DB_TYPE`        | Variable PRESTASHOP_DB_TYPE.     | `none`  |                  |
| `PRESTASHOP_WEBSERVER`      | Variable PRESTASHOP_WEBSERVER.   | `none`  |                  |
| `PRESTASHOP_DB_USER`        | Variable PRESTASHOP_DB_USER.     | `none`  |                  |
| `PRESTASHOP_WWWROOT`        | Variable WWWROOT.                | `none`  |                  |
| `PRESTASHOP_VERSION`        | Variable PRESTASHOP_VERSION.     | `none`  |                  |
| `PRESTASHOP_LISTEN`         | Variable PRESTASHOP_LISTEN.      | `none`  |                  |
| `PRESTASHOP_SERVER_NAME`    | Variable PRESTASHOP_SERVER_NAME. | `none`  |                  |
| `PRESTASHOP_DB_NAME`        | Variable PRESTASHOP_DB_NAME.     | `none`  |                  |
| `PRESTASHOP_DB_PASS`        | Variable PRESTASHOP_DB_PASS.     | `none`  |                  |

<!-- END_VARS -->

## Supported OS

- Linux
- FreeBSD
- macOS
- Windows

## Supported Databases

- MariaDB / MySQL
- PostgreSQL (via CLI logic, verify PrestaShop driver support)
- SQLite (via CLI logic, verify PrestaShop driver support)

## Supported Webservers

- Nginx
- Caddy
- Apache HTTPD
- IIS

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/php`: PHP runtime and extensions (intl, gd, zip, pdo_mysql)
- `_lib/databases/mariadb` (or `postgres`, `sqlite`): Relational backend
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server
