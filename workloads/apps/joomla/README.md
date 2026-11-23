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

| Variable                | Description                                                                         | Default |
| :---------------------- | :---------------------------------------------------------------------------------- | :------ |
| `JOOMLA_VERSION`        | Target Joomla CMS release version or semantic alias (e.g., latest) to install.      | `-`     |
| `JOOMLA_DB_PASS`        | Database password used by Joomla to authenticate against its relational database.   | `-`     |
| `JOOMLA_PHP_FPM_LISTEN` | PHP-FPM upstream FastCGI socket path or host:port endpoint serving Joomla requests. | `-`     |
| `JOOMLA_LISTEN`         | HTTP bind address:port or UNIX socket endpoint exposed by the Joomla web server.    | `-`     |
| `JOOMLA_DB_TYPE`        | Database driver backend for Joomla (e.g., mysqli, pgsql, mysql).                    | `-`     |
| `JOOMLA_WEBSERVER`      | Frontend web server component fronting Joomla (e.g., nginx, caddy, httpd).          | `-`     |
| `JOOMLA_WWWROOT`        | Filesystem document root directory where Joomla source files are deployed.          | `-`     |
| `JOOMLA_DB_USER`        | Database role or username granted ownership of the Joomla schema.                   | `-`     |
| `JOOMLA_SERVER_NAME`    | Virtual host domain or server_name configured for Joomla HTTP/TLS routing.          | `-`     |
| `JOOMLA_DB_NAME`        | Relational database name provisioned for Joomla content and metadata.               | `-`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

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
