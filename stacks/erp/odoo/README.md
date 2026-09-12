# Odoo

## Usage

This document describes the `Odoo` component within the LibScript ecosystem. This module installs
Odoo alongside a webserver and a database (typically PostgreSQL).

It works both as a local version manager and can be invoked from the global version manager
`libscript`. Furthermore, this component can be used by libscript to build bigger stacks by
composing it with caching layers, load balancers, or other services.

You can manage Odoo using the global `libscript` CLI or local scripts.

- **Install:** `libscript install odoo`
- **Uninstall:** `libscript uninstall odoo`
- **Start:** `libscript start odoo`
- **Stop:** `libscript stop odoo`
- **Package:** `libscript package-as docker odoo` (or `msi`, `docker_compose`, etc.)

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable           | Description                | Default | Aliases/Examples |
| ------------------ | -------------------------- | ------- | ---------------- |
| `ODOO_DB_TYPE`     | Variable ODOO_DB_TYPE.     | `none`  |                  |
| `ODOO_LISTEN`      | Variable ODOO_LISTEN.      | `none`  |                  |
| `ODOO_VERSION`     | Variable ODOO_VERSION.     | `none`  |                  |
| `ODOO_DB_USER`     | Variable ODOO_DB_USER.     | `none`  |                  |
| `ODOO_DB_HOST`     | Variable ODOO_DB_HOST.     | `none`  |                  |
| `ODOO_WEBSERVER`   | Variable ODOO_WEBSERVER.   | `none`  |                  |
| `ODOO_WWWROOT`     | Variable WWWROOT.          | `none`  |                  |
| `ODOO_SERVER_NAME` | Variable ODOO_SERVER_NAME. | `none`  |                  |
| `ODOO_DB_NAME`     | Variable ODOO_DB_NAME.     | `none`  |                  |
| `ODOO_DB_PASS`     | Variable ODOO_DB_PASS.     | `none`  |                  |
| `ODOO_DB_PORT`     | Variable ODOO_DB_PORT.     | `none`  |                  |
| `ODOO_PORT`        | Variable ODOO_PORT.        | `none`  |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/python`: Python runtime and Odoo application framework
- `_lib/databases/postgres`: PostgreSQL database server
- `_lib/web-servers/nginx` (or `caddy`, `httpd`): Reverse proxy and static file server
