# Phpbb

This module automates the setup of phpBB.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                    | Default | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------ | ------- | ---------------- |
| `PHPBB_LISTEN`         | HTTP bind address:port or UNIX socket endpoint configured for phpBB.           | `none`  |                  |
| `PHPBB_PHP_FPM_LISTEN` | PHP-FPM FastCGI upstream socket or host:port endpoint executing phpBB scripts. | `none`  |                  |
| `PHPBB_SERVER_NAME`    | Virtual host domain or hostname serving the phpBB forum.                       | `none`  |                  |
| `PHPBB_WEBSERVER`      | Frontend web server component fronting phpBB (e.g., nginx, caddy, httpd).      | `none`  |                  |
| `PHPBB_VERSION`        | Target phpBB release version or alias (e.g., latest) to install.               | `none`  |                  |
| `PHPBB_DB_PASS`        | Database password authenticating the phpBB database account.                   | `none`  |                  |
| `PHPBB_DB_TYPE`        | Database driver backend for phpBB (e.g., postgres, mysql, mariadb, sqlite3).   | `none`  |                  |
| `PHPBB_WWWROOT`        | Filesystem document root directory containing the unpacked phpBB installation. | `none`  |                  |
| `PHPBB_DB_NAME`        | Database name storing phpBB forum topics, users, and configuration.            | `none`  |                  |
| `PHPBB_DB_USER`        | Database username used by phpBB to connect to its database.                    | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
