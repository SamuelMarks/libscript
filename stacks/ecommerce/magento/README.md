Magento
=======

This component installs and configures Magento.

## Environment Variables
- `MAGENTO_VERSION`: The version of Magento to install (default: `2.4.6`).
- `MAGENTO_WEBSERVER`: The web server to configure (`nginx`, `caddy`, `httpd`, `iis` on Windows) (default: `nginx`).
- `MAGENTO_DB_DRIVER`: The database driver to use (`mariadb`, `postgres`, `sqlite`) (default: `mariadb`).
- `MAGENTO_DB_HOST`: The database host (default: `127.0.0.1`).
- `MAGENTO_DB_NAME`: The database name (default: `magento`).
- `MAGENTO_DB_USER`: The database user (default: `magento`).
- `MAGENTO_DB_PASS`: The database password (default: `magento`).
- `MAGENTO_SERVER_NAME`: The server name for the web server configuration (default: `localhost`).
- `MAGENTO_LISTEN`: The port to listen on (default: `80`).
- `WWWROOT`: The directory to install Magento to (default: `/var/www/magento` on Linux, `C:\inetpub\wwwroot\magento` on Windows).

## Dependencies
- PHP and PHP-FPM
- Composer
- Web Server (nginx, caddy, httpd, or IIS)
- Database (mariadb, postgres, or sqlite)

## Usage
```bash
MAGENTO_VERSION=2.4.6 \
MAGENTO_WEBSERVER=nginx \
MAGENTO_DB_DRIVER=mariadb \
./setup.sh
```

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
