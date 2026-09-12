# Phpbb

This module automates the setup of phpBB.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                 | Default | Aliases/Examples |
| ---------------------- | --------------------------- | ------- | ---------------- |
| `PHPBB_LISTEN`         | Variable PHPBB_LISTEN.      | `none`  |                  |
| `PHPBB_PHP_FPM_LISTEN` | Variable PHP_FPM_LISTEN.    | `none`  |                  |
| `PHPBB_SERVER_NAME`    | Variable PHPBB_SERVER_NAME. | `none`  |                  |
| `PHPBB_WEBSERVER`      | Variable PHPBB_WEBSERVER.   | `none`  |                  |
| `PHPBB_VERSION`        | Variable PHPBB_VERSION.     | `none`  |                  |
| `PHPBB_DB_PASS`        | Variable PHPBB_DB_PASS.     | `none`  |                  |
| `PHPBB_DB_TYPE`        | Variable PHPBB_DB_TYPE.     | `none`  |                  |
| `PHPBB_WWWROOT`        | Variable WWWROOT.           | `none`  |                  |
| `PHPBB_DB_NAME`        | Variable PHPBB_DB_NAME.     | `none`  |                  |
| `PHPBB_DB_USER`        | Variable PHPBB_DB_USER.     | `none`  |                  |

<!-- END_VARS -->

## Supported OS

- Linux
- FreeBSD
- macOS
- Windows

## Supported Databases

- SQLite
- MariaDB / MySQL
- PostgreSQL

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

- `_lib/languages/php`: PHP runtime and required extensions (curl, gd, mbstring, xml, zip)
- `_lib/databases/sqlite` (or `mariadb`, `postgres`): Backend database
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server for HTTP reverse proxy and
  static asset delivery
