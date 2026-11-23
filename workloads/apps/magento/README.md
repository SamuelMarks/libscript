# Magento

This component installs and configures Magento.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                    | Default |
| :----------------------- | :----------------------------------------------------------------------------- | :------ |
| `MAGENTO_PHP_FPM_LISTEN` | PHP-FPM FastCGI socket path or host:port endpoint serving Magento PHP workers. | `-`     |
| `MAGENTO_DB_HOST`        | Hostname or IP address of the MySQL/MariaDB server backing Magento.            | `-`     |
| `MAGENTO_WEBSERVER`      | Frontend web server component fronting Magento (e.g., nginx, caddy, httpd).    | `-`     |
| `MAGENTO_VERSION`        | Target Magento open-source release version or alias (e.g., latest) to install. | `-`     |
| `MAGENTO_SERVER_NAME`    | Public virtual host domain name configured for the Magento storefront.         | `-`     |
| `MAGENTO_WWWROOT`        | Filesystem root directory where the Magento application tree is deployed.      | `-`     |
| `MAGENTO_DB_PASS`        | Password authenticating the Magento database user.                             | `-`     |
| `MAGENTO_DB_DRIVER`      | Database driver backend used by Magento (e.g., mysql, mariadb).                | `-`     |
| `MAGENTO_LISTEN`         | HTTP bind address:port or UNIX socket configured on the Magento web server.    | `-`     |
| `MAGENTO_DB_USER`        | Database username granted privileges on the Magento schema.                    | `-`     |
| `MAGENTO_DB_NAME`        | Database name provisioned for Magento catalog, order, and customer data.       | `-`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

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
