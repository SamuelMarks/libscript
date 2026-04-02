Odoo
====

## Usage
This document describes the `Odoo` component within the LibScript ecosystem. This module installs Odoo alongside a webserver and a database (typically PostgreSQL).

It works both as a local version manager and can be invoked from the global version manager `libscript`. Furthermore, this component can be used by libscript to build bigger stacks by composing it with caching layers, load balancers, or other services.

## Usage
You can manage Odoo using the global `libscript` CLI or local scripts.

- **Install:** `libscript install odoo`
- **Uninstall:** `libscript uninstall odoo`
- **Start:** `libscript start odoo`
- **Stop:** `libscript stop odoo`
- **Package:** `libscript package_as docker odoo` (or `msi`, `docker_compose`, etc.)

## Environment Variables
- `ODOO_VERSION`: Specific Odoo version branch/tag to install (default `17.0`).
- `ODOO_WEBSERVER`: One of `nginx` (default), `caddy`, `httpd`, or `iis`.
- `ODOO_SERVER_NAME`: The FQDN for the application (default `localhost`).
- `ODOO_LISTEN`: The port the webserver listens on (default `80`).
- `ODOO_PORT`: The internal port Odoo listens on (default `8069`).
- `WWWROOT`: The directory to install to (default `/var/www/odoo` or `C:\inetpub\wwwroot\odoo`).
- `ODOO_DB_TYPE`: The database to use (default `postgres`).
- `ODOO_DB_NAME`, `ODOO_DB_USER`, `ODOO_DB_PASS`, `ODOO_DB_HOST`, `ODOO_DB_PORT`: Database credentials and connection info.

## Platform Support
This module adheres to LibScript's cross-platform conventions:
- Supports Linux, macOS, FreeBSD, and Windows.
- Uses `setup_win.ps1` for clean `.msi` or `.exe` Windows Installer generation, leveraging `winget` and native IIS PowerShell configuration blocks (`WebAdministration`).

## Variables
See `vars.schema.json` for details on available variables.
