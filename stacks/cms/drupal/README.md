# Drupal

Installs Drupal natively via release tarball with webserver and DB configuration.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                  | Default | Aliases/Examples |
| ----------------------- | ---------------------------- | ------- | ---------------- |
| `DRUPAL_PHP_FPM_LISTEN` | Variable PHP_FPM_LISTEN.     | `none`  |                  |
| `DRUPAL_DB_TYPE`        | Variable DRUPAL_DB_TYPE.     | `none`  |                  |
| `DRUPAL_DB_NAME`        | Variable DRUPAL_DB_NAME.     | `none`  |                  |
| `DRUPAL_DB_USER`        | Variable DRUPAL_DB_USER.     | `none`  |                  |
| `DRUPAL_WWWROOT`        | Variable WWWROOT.            | `none`  |                  |
| `DRUPAL_SERVER_NAME`    | Variable DRUPAL_SERVER_NAME. | `none`  |                  |
| `DRUPAL_VERSION`        | Variable DRUPAL_VERSION.     | `none`  |                  |
| `DRUPAL_DB_PASS`        | Variable DRUPAL_DB_PASS.     | `none`  |                  |
| `DRUPAL_WEBSERVER`      | Variable DRUPAL_WEBSERVER.   | `none`  |                  |
| `DRUPAL_LISTEN`         | Variable DRUPAL_LISTEN.      | `none`  |                  |

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
