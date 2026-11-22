# Prestashop

This module automates the setup of PrestaShop.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                       | Default | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------- | ------- | ---------------- |
| `PRESTASHOP_PHP_FPM_LISTEN` | PHP-FPM upstream FastCGI socket path or host:port endpoint serving PrestaShop.    | `none`  |                  |
| `PRESTASHOP_DB_TYPE`        | Relational database engine type used by PrestaShop (e.g., mysql, mariadb).        | `none`  |                  |
| `PRESTASHOP_WEBSERVER`      | Frontend web server component fronting PrestaShop (e.g., nginx, caddy, httpd).    | `none`  |                  |
| `PRESTASHOP_DB_USER`        | Database username used by PrestaShop to connect to its backing store.             | `none`  |                  |
| `PRESTASHOP_WWWROOT`        | Filesystem document root directory where PrestaShop application files are staged. | `none`  |                  |
| `PRESTASHOP_VERSION`        | Target PrestaShop release version or alias (e.g., latest) to deploy.              | `none`  |                  |
| `PRESTASHOP_LISTEN`         | HTTP listen address:port or UNIX socket endpoint configured for PrestaShop.       | `none`  |                  |
| `PRESTASHOP_SERVER_NAME`    | Public virtual host domain name configured for the PrestaShop storefront.         | `none`  |                  |
| `PRESTASHOP_DB_NAME`        | Database schema name created for PrestaShop e-commerce tables.                    | `none`  |                  |
| `PRESTASHOP_DB_PASS`        | Database password authenticating the PrestaShop database user.                    | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

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

- `_lib/languages/php`: PHP runtime and extensions (intl, gd, zip, pdo_mysql)
- `_lib/databases/mariadb` (or `postgres`, `sqlite`): Relational backend
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server
