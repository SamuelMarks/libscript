# Drupal

Installs Drupal natively via release tarball with webserver and DB configuration.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                      | Default     | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------- | ----------- | ---------------- |
| `DRUPAL_PHP_FPM_LISTEN` | PHP-FPM FastCGI socket path or host:port endpoint executing Drupal PHP requests. | `none`      |                  |
| `DRUPAL_DB_TYPE`        | Database backend driver for Drupal (e.g., mysql, pgsql, sqlite).                 | `none`      |                  |
| `DRUPAL_DB_NAME`        | Database schema name provisioned for the Drupal site.                            | `none`      |                  |
| `DRUPAL_DB_USER`        | Database username used by Drupal for database connections.                       | `none`      |                  |
| `DRUPAL_WWWROOT`        | Filesystem webroot directory where Drupal core and modules are installed.        | `none`      |                  |
| `DRUPAL_SERVER_NAME`    | Virtual host domain name configured for the Drupal web server.                   | `none`      |                  |
| `DRUPAL_VERSION`        | Target Drupal core version or semantic alias (e.g., latest) to deploy.           | `none`      |                  |
| `DRUPAL_DB_PASS`        | Password authenticating the Drupal database user.                                | `none`      |                  |
| `DRUPAL_WEBSERVER`      | Frontend web server fronting Drupal (e.g., nginx, caddy, httpd).                 | `none`      |                  |
| `DRUPAL_LISTEN`         | HTTP listen address:port or UNIX socket exposed by the Drupal web server.        | `none`      |                  |
| `db_strategy`           | Database provisioning strategy (local managed instance vs remote server).        | `local`     |                  |
| `db_host`               | Database connection host.                                                        | `127.0.0.1` |                  |
| `db_name`               | Database name.                                                                   | `drupal`    |                  |
| `db_url`                | Full database connection string or URL.                                          | `none`      |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

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

- `_lib/languages/php`: PHP engine and CLI tools
- `_lib/databases/sqlite` (or `mariadb`, `postgres`): Application database
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web frontend and request handler
