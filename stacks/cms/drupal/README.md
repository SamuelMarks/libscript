# Drupal

Installs Drupal natively via release tarball with webserver and DB configuration.

## Environment Variables

- `DRUPAL_VERSION`: Default `10.2.6`
- `DRUPAL_WEBSERVER`: Webserver to use (e.g., `nginx`, `caddy`, `httpd`, `iis`). Default `nginx`
- `DRUPAL_DB_TYPE`: Database to use (`sqlite`, `mariadb`, `postgres`). Default `sqlite`
- `DRUPAL_DB_NAME`: Database name
- `DRUPAL_DB_USER`: Database user
- `DRUPAL_DB_PASS`: Database password
- `DRUPAL_SERVER_NAME`: Web server domain name
- `DRUPAL_LISTEN`: Web server port
- `WWWROOT`: Path to install Drupal

## Variables

See `vars.schema.json` for details on available variables.
