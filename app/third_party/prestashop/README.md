# PrestaShop setup module

This module automates the setup of PrestaShop.

## Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `PRESTASHOP_VERSION` | PrestaShop version to install | `8.2.4` |
| `PRESTASHOP_WEBSERVER` | Webserver to use (`nginx`, `caddy`, `httpd`, `iis`) | `nginx` |
| `PRESTASHOP_DB_TYPE` | Database to use (`sqlite`, `mariadb`, `postgres`) | `mariadb` |
| `PRESTASHOP_DB_NAME` | Database name | `prestashop` |
| `PRESTASHOP_DB_USER` | Database user | `prestashop` |
| `PRESTASHOP_DB_PASS` | Database password | `prestashop` |
| `PRESTASHOP_SERVER_NAME` | Server name for webserver config | `localhost` |
| `PRESTASHOP_LISTEN` | Port to listen on | `80` |
| `WWWROOT` | Directory to install PrestaShop | `/var/www/prestashop` (Linux), `C:\inetpub\wwwroot\prestashop` (Windows) |
| `PHP_FPM_LISTEN` | PHP FPM socket or address | OS specific |

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
