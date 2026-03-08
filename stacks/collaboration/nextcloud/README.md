# Nextcloud LibScript Module

## Overview
This document describes the `Nextcloud` component within the LibScript ecosystem. This module installs Nextcloud alongside a webserver and MariaDB database.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. Furthermore, this component can be used by libscript to build bigger stacks (like Nextcloud, Open edX, nextcloud, etc.) by composing it with caching layers, load balancers, or other services.

## LibScript Operations
You can manage Nextcloud using the global `libscript` CLI or local scripts.

- **Install:** `libscript install nextcloud`
- **Uninstall:** `libscript uninstall nextcloud`
- **Start:** `libscript start nextcloud`
- **Stop:** `libscript stop nextcloud`
- **Package:** `libscript package_as docker nextcloud` (or `msi`, `docker_compose`, etc.)

## Environment Variables

- `NEXTCLOUD_VERSION`: Specific Nextcloud version to install (default `latest`).
- `NEXTCLOUD_WEBSERVER`: One of `nginx` (default on Linux/macOS), `caddy`, `httpd`, or `iis` (default on Windows).
- `NEXTCLOUD_SERVER_NAME`: The FQDN for the application (default `localhost`).
- `NEXTCLOUD_LISTEN`: The port to listen on (default `80`).
- `WWWROOT`: The directory to install to (default `/var/www/nextcloud` or `C:\inetpub\wwwroot\nextcloud`).
- `NEXTCLOUD_DB_TYPE`: One of `sqlite`, `mariadb`, `postgres` (default `sqlite`).
- `NEXTCLOUD_DB_NAME`, `NEXTCLOUD_DB_USER`, `NEXTCLOUD_DB_PASS`: Database credentials.
- `PHP_FPM_LISTEN`: Unix socket or host:port for PHP-FPM connection (auto-detected if unset).

## OS Compatibility & Packaging

This module adheres to LibScript's cross-platform conventions:
- Safely degrades system-level reloads (e.g. `systemctl`, `mysql`) during image build phases, ensuring `package_as docker` emits a single, functional container.
- Uses `setup_win.ps1` for clean `.msi` or `.exe` Windows Installer generation, leveraging `winget` and native IIS PowerShell configuration blocks (`WebAdministration`).

## Variables

See `vars.schema.json` for details on available variables.
