Joomla
======

A generic setup script to deploy the [Joomla! CMS](https://www.joomla.org/) using LibScript.

## Features Supported
- Fully automated download and extraction of the latest (or specific) Joomla release.
- Web server integration: Nginx, Caddy, HTTPD (Apache), IIS (Windows).
- Database configuration: MariaDB/MySQL, PostgreSQL.

## Environment Variables
| Variable | Description | Default |
| -------- | ----------- | ------- |
| `JOOMLA_VERSION` | Version of Joomla to install (or `latest`). | `latest` |
| `JOOMLA_WEBSERVER` | Target web server (`nginx`, `caddy`, `httpd`, `iis`). | `nginx` |
| `JOOMLA_DB_TYPE` | Database driver to use (`mariadb`, `postgres`). | `mariadb` |
| `JOOMLA_DB_NAME` | Name of the database. | `joomla` |
| `JOOMLA_DB_USER` | Database user name. | `joomla` |
| `JOOMLA_DB_PASS` | Database user password. | `joomla` |
| `JOOMLA_SERVER_NAME` | Virtual Host server name (domain). | `localhost` |
| `JOOMLA_LISTEN` | Web server listen port. | `80` |
| `WWWROOT` | Path to extract and serve Joomla from. | `/var/www/joomla` (Linux/macOS) / `C:\inetpub\wwwroot\joomla` (Windows) |

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

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
