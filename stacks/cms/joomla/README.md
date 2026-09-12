# Joomla

A generic setup script to deploy the [Joomla! CMS](https://www.joomla.org/) using LibScript.

## Features Supported

- Fully automated download and extraction of the latest (or specific) Joomla release.
- Web server integration: Nginx, Caddy, HTTPD (Apache), IIS (Windows).
- Database configuration: MariaDB/MySQL, PostgreSQL.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                  | Default | Aliases/Examples |
| ----------------------- | ---------------------------- | ------- | ---------------- |
| `JOOMLA_VERSION`        | Variable JOOMLA_VERSION.     | `none`  |                  |
| `JOOMLA_DB_PASS`        | Variable JOOMLA_DB_PASS.     | `none`  |                  |
| `JOOMLA_PHP_FPM_LISTEN` | Variable PHP_FPM_LISTEN.     | `none`  |                  |
| `JOOMLA_LISTEN`         | Variable JOOMLA_LISTEN.      | `none`  |                  |
| `JOOMLA_DB_TYPE`        | Variable JOOMLA_DB_TYPE.     | `none`  |                  |
| `JOOMLA_WEBSERVER`      | Variable JOOMLA_WEBSERVER.   | `none`  |                  |
| `JOOMLA_WWWROOT`        | Variable WWWROOT.            | `none`  |                  |
| `JOOMLA_DB_USER`        | Variable JOOMLA_DB_USER.     | `none`  |                  |
| `JOOMLA_SERVER_NAME`    | Variable JOOMLA_SERVER_NAME. | `none`  |                  |
| `JOOMLA_DB_NAME`        | Variable JOOMLA_DB_NAME.     | `none`  |                  |

<!-- END_VARS -->

## Example Usage

### Linux / macOS (Nginx + MariaDB)

```sh
export JOOMLA_WEBSERVER="nginx"
export JOOMLA_DB_TYPE="mariadb"
export JOOMLA_VERSION="latest"
./setup.sh
```

### Windows (IIS + PostgreSQL)

```cmd
set JOOMLA_WEBSERVER=iis
set JOOMLA_DB_TYPE=postgres
set JOOMLA_VERSION=5.2.0
setup.cmd
```

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

- `_lib/languages/php`: PHP runtime and database drivers
- `_lib/databases/mariadb` (or `postgres`): Relational database storage
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server
