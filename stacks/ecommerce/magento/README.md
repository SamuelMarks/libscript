# Magento

This component installs and configures Magento.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                   | Default | Aliases/Examples |
| ------------------------ | ----------------------------- | ------- | ---------------- |
| `MAGENTO_PHP_FPM_LISTEN` | Variable PHP_FPM_LISTEN.      | `none`  |                  |
| `MAGENTO_DB_HOST`        | Variable MAGENTO_DB_HOST.     | `none`  |                  |
| `MAGENTO_WEBSERVER`      | Variable MAGENTO_WEBSERVER.   | `none`  |                  |
| `MAGENTO_VERSION`        | Variable MAGENTO_VERSION.     | `none`  |                  |
| `MAGENTO_SERVER_NAME`    | Variable MAGENTO_SERVER_NAME. | `none`  |                  |
| `MAGENTO_WWWROOT`        | Variable WWWROOT.             | `none`  |                  |
| `MAGENTO_DB_PASS`        | Variable MAGENTO_DB_PASS.     | `none`  |                  |
| `MAGENTO_DB_DRIVER`      | Variable MAGENTO_DB_DRIVER.   | `none`  |                  |
| `MAGENTO_LISTEN`         | Variable MAGENTO_LISTEN.      | `none`  |                  |
| `MAGENTO_DB_USER`        | Variable MAGENTO_DB_USER.     | `none`  |                  |
| `MAGENTO_DB_NAME`        | Variable MAGENTO_DB_NAME.     | `none`  |                  |

<!-- END_VARS -->

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

- `_lib/languages/php`: PHP runtime with OPcache, sodium, and required extensions
- `_lib/databases/mariadb`: Relational database engine
- `_lib/caches/redis`: Session and full page caching
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server configuration
