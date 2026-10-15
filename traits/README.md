# The Unified Traits Subsystem (`traits/`)

## Overview

`traits/` provides composable, cross-cutting node and sysroot capabilities that bind Tier 1
components (`_lib/`) to host storage, zero-leak secret pipelines, firewalls, encrypted mesh
networks, service discovery, reverse proxies (`netctl`), TLS PKI, observability, and CoW/object
backups.

## Execution Order & Dual-Mode Context Contract

`traits/engine.sh` and `traits/engine.cmd` resolve and execute traits in deterministic priority
order:

1. `storage` (`10`)
2. `secrets` (`20`)
3. `mesh` (`30`)
4. `firewall` (`40`)
5. `discovery` (`50`)
6. `tls` (`60`)
7. `ingress` (`70`)
8. `logging` (`80`)
9. `metrics` (`90`)
10. `backup` (`100`)
11. `maintenance` (`110`)

Every trait inspects `LIBSCRIPT_TARGET_SYSROOT`:

- **Tier 2 Offline Sysroot Bake Mode (`LIBSCRIPT_TARGET_SYSROOT != /`)**: Emits configuration files
  (`/etc/fstab`, `/etc/vfstab`, `/etc/nftables.conf`, `/etc/pf.conf`, cron/systemd timers) directly
  into the target sysroot without executing live kernel syscalls when `LIBSCRIPT_OFFLINE=1`.
- **Tier 3 Live Runtime Mode (`LIBSCRIPT_TARGET_SYSROOT == /`)**: Formats unformatted block devices,
  mounts filesystems, reloads host firewalls with anti-lockout rules, brings up WireGuard meshes,
  and reloads reverse proxies with zero downtime.

## Usage

```sh
./libscript.sh trait list
./libscript.sh trait apply storage
./libscript.sh trait verify firewall
./libscript.sh trait teardown ingress
```
