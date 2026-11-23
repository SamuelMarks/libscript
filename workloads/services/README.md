# Tier 5 (`T5`) Stack Service Lifecycle & Deployment (`workloads/services/`)

## Overview

`workloads/services/` implements local and remote `libscript.json` stack lifecycle orchestration,
bridging `T1` daemons, `Plane A` node traits (`ingress`, `tls`, `secrets`, `storage`), and `T0`
service supervisors (`systemd`, `openrc`, `launchd`, `smf`, Windows Services).

## Modules

- **`actions.{sh,cmd}`**: Handles
  `./libscript.sh <start|stop|restart|status|health|logs|up|down|uninstall-service|deprovision-db|export-state|import-state|prepare-storage>`
  across single components or entire `libscript.json` service graphs.
- **`deploy.{sh,cmd}`**: Idempotent local stack deployment (`./libscript.sh deploy [dir]`),
  resolving dependencies, running database migrations, registering init units, and reloading
  `netctl` ingress.
- **`deploy-remote.{sh,cmd}`**: Agentless SSH / `rsync` / `scp` / WinRM remote host stack deployment
  (`./libscript.sh deploy-remote <user@host> <local_dir> [remote_dir]`).

## Usage

```sh
./libscript.sh up
./libscript.sh status all
./libscript.sh deploy ./
./libscript.sh deploy-remote deploy@prod.example.com ./ /srv/app
```

```cmd
.\libscript.cmd up
.\libscript.cmd status all
.\libscript.cmd deploy .\
```
