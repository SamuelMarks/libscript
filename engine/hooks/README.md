# Tier 0 (`T0`) Decoupled Integration Hook Runner (`engine/hooks/`)

## Overview

`engine/hooks/` provides the `T0` contract-based integration hook dispatcher
(`run_hooks.{sh,cmd,ps1}`) that connects `T5` application stacks (`workloads/apps/`) to `T1`
databases, application servers, and reverse-proxy web servers without allowing lateral
cross-component sourcing inside `_lib/`.

## Subdirectories & Hook Contracts

- **`run_hooks.{sh,cmd,ps1}`**: Dispatches typed integration hooks across installed providers with
  caller context (`THIS_FILE` / `SCRIPT_DIR`) preservation.
- **`databases/`**: Logical database lifecycle hooks (`provision_db.{sh,cmd}`,
  `deprovision_db.{sh,cmd}`) creating/dropping isolated databases, roles, and credentials across
  PostgreSQL, MariaDB/MySQL, MongoDB, SQLite, and Valkey/Redis.
- **`app-servers/`**: Application worker registration hooks (`provision_wsgi.{sh,cmd}`,
  `provision_frontend.{sh,cmd}`) binding Python WSGI/ASGI, PHP-FPM, Node.js, or Ruby workers.
- **`web-servers/`**: Ingress vhost and upstream routing hooks (`provision_vhost.{sh,cmd}`) emitting
  site configurations for Nginx, Caddy, Apache `httpd`, Traefik, or Windows IIS via `netctl`.

## Usage

```sh
./engine/hooks/run_hooks.sh --help
```

```cmd
.\engine\hooks\run_hooks.cmd --help
```
