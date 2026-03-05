# WordPress LibScript Module

This module installs WordPress alongside a webserver and MariaDB database.
It natively supports deploying to Nginx, Caddy, or HTTPD on POSIX systems, and Microsoft IIS on Windows.

## Environment Variables

- `WORDPRESS_VERSION`: Specific WordPress version to install (default `latest`).
- `WORDPRESS_WEBSERVER`: One of `nginx` (default on Linux/macOS), `caddy`, `httpd`, or `iis` (default on Windows).
- `WORDPRESS_SERVER_NAME`: The FQDN for the application (default `localhost`).
- `WORDPRESS_LISTEN`: The port to listen on (default `80`).
- `WWWROOT`: The directory to install to (default `/var/www/wordpress` or `C:\inetpub\wwwroot\wordpress`).
- `WORDPRESS_DB_NAME`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASS`: Database credentials.
- `PHP_FPM_LISTEN`: Unix socket or host:port for PHP-FPM connection (auto-detected if unset).

## OS Compatibility & Packaging

This module adheres to LibScript's cross-platform conventions:
- Safely degrades system-level reloads (e.g. `systemctl`, `mysql`) during image build phases, ensuring `package_as docker` emits a single, functional container.
- Uses `setup_win.ps1` for clean `.msi` or `.exe` Windows Installer generation, leveraging `winget` and native IIS PowerShell configuration blocks (`WebAdministration`).
