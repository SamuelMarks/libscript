# Magento

This component installs and configures Magento.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                    | Default | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------ | ------- | ---------------- |
| `MAGENTO_PHP_FPM_LISTEN` | PHP-FPM FastCGI socket path or host:port endpoint serving Magento PHP workers. | `none`  |                  |
| `MAGENTO_DB_HOST`        | Hostname or IP address of the MySQL/MariaDB server backing Magento.            | `none`  |                  |
| `MAGENTO_WEBSERVER`      | Frontend web server component fronting Magento (e.g., nginx, caddy, httpd).    | `none`  |                  |
| `MAGENTO_VERSION`        | Target Magento open-source release version or alias (e.g., latest) to install. | `none`  |                  |
| `MAGENTO_SERVER_NAME`    | Public virtual host domain name configured for the Magento storefront.         | `none`  |                  |
| `MAGENTO_WWWROOT`        | Filesystem root directory where the Magento application tree is deployed.      | `none`  |                  |
| `MAGENTO_DB_PASS`        | Password authenticating the Magento database user.                             | `none`  |                  |
| `MAGENTO_DB_DRIVER`      | Database driver backend used by Magento (e.g., mysql, mariadb).                | `none`  |                  |
| `MAGENTO_LISTEN`         | HTTP bind address:port or UNIX socket configured on the Magento web server.    | `none`  |                  |
| `MAGENTO_DB_USER`        | Database username granted privileges on the Magento schema.                    | `none`  |                  |
| `MAGENTO_DB_NAME`        | Database name provisioned for Magento catalog, order, and customer data.       | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
