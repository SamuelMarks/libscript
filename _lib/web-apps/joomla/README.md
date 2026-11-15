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

| Variable                | Description                                                                         | Default | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------- | ------- | ---------------- |
| `JOOMLA_VERSION`        | Target Joomla CMS release version or semantic alias (e.g., latest) to install.      | `none`  |                  |
| `JOOMLA_DB_PASS`        | Database password used by Joomla to authenticate against its relational database.   | `none`  |                  |
| `JOOMLA_PHP_FPM_LISTEN` | PHP-FPM upstream FastCGI socket path or host:port endpoint serving Joomla requests. | `none`  |                  |
| `JOOMLA_LISTEN`         | HTTP bind address:port or UNIX socket endpoint exposed by the Joomla web server.    | `none`  |                  |
| `JOOMLA_DB_TYPE`        | Database driver backend for Joomla (e.g., mysqli, pgsql, mysql).                    | `none`  |                  |
| `JOOMLA_WEBSERVER`      | Frontend web server component fronting Joomla (e.g., nginx, caddy, httpd).          | `none`  |                  |
| `JOOMLA_WWWROOT`        | Filesystem document root directory where Joomla source files are deployed.          | `none`  |                  |
| `JOOMLA_DB_USER`        | Database role or username granted ownership of the Joomla schema.                   | `none`  |                  |
| `JOOMLA_SERVER_NAME`    | Virtual host domain or server_name configured for Joomla HTTP/TLS routing.          | `none`  |                  |
| `JOOMLA_DB_NAME`        | Relational database name provisioned for Joomla content and metadata.               | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
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
