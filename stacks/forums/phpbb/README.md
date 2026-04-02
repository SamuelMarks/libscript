Phpbb
=====

This module automates the setup of phpBB.

## Environment Variables
| Variable | Description | Default |
| --- | --- | --- |
| `PHPBB_VERSION` | phpBB version to install | `3.3.11` |
| `PHPBB_WEBSERVER` | Webserver to use (`nginx`, `caddy`, `httpd`, `iis`) | `nginx` |
| `PHPBB_DB_TYPE` | Database to use (`sqlite`, `mariadb`, `postgres`) | `sqlite` |
| `PHPBB_DB_NAME` | Database name | `phpbb` |
| `PHPBB_DB_USER` | Database user | `phpbb` |
| `PHPBB_DB_PASS` | Database password | `phpbb` |
| `PHPBB_SERVER_NAME` | Server name for webserver config | `localhost` |
| `PHPBB_LISTEN` | Port to listen on | `80` |
| `WWWROOT` | Directory to install phpBB | `/var/www/phpbb` (Linux), `C:\inetpub\wwwroot\phpbb` (Windows) |
| `PHP_FPM_LISTEN` | PHP FPM socket or address | OS specific |

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

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
