# Plane A: Cross-Cutting Node & Sysroot Traits (`traits/`)

## Overview

`traits/` (`Plane A`) provides orthogonal, cross-cutting node and sysroot capabilities that bind
atomic `T1`/`T2` components (`_lib/`) to storage mounts, zero-leak secret pipelines, host firewalls,
encrypted WireGuard/Tailscale meshes, service discovery, mTLS/ACME PKI, reverse-proxy ingress,
log/metric telemetry, Copy-on-Write + object-storage backups, and maintenance schedules.

Every trait conforms to `traits/trait.schema.json` and operates seamlessly in two execution modes
(strictly downward-importing `T0`–`T2` only, as enforced by `devtools/audit/audit_tiers.{sh,cmd}`):

- **`T3` Offline Sysroot Bake Mode (`--sysroot <path>` / `LIBSCRIPT_TARGET_SYSROOT`)**: Writes
  static `/etc/fstab` entries, firewall rulesets, WireGuard configs, internal PKI trust roots, and
  systemd/cron timers directly into a target sysroot without invoking live kernel syscalls or
  contacting cloud APIs.
- **`T4` / `T5` Live Runtime Mode**: Formats and mounts volumes (`engine/common/format_fs.*`),
  streams secrets over `0600` FIFOs/tmpfs pipes without environment variable leakage, brings up
  encrypted mesh tunnels, applies firewall policies with anti-lockout rollback, and reloads `netctl`
  reverse proxies with zero downtime.

## Trait Catalog

- [`storage/`](./storage/README.md): Block, NFS, SMB, `gcsfuse`, and 4-role regional GCS ML buckets.
- [`secrets/`](./secrets/README.md): Zero-env-leak FIFO/pipe secret injection from OpenBao/Vault,
  SOPS, and `0600` `.env` files.
- [`firewall/`](./firewall/README.md): Declarative host firewall compiler (`nftables`, `iptables`,
  `ufw`, BSD `pf`, Windows `netsh advfirewall`) with SSH anti-lockout safeguards.
- [`mesh/`](./mesh/README.md): Encrypted node-to-node overlay networking via WireGuard and
  Tailscale.
- [`discovery/`](./discovery/README.md): `/etc/hosts` synthesis, mDNS (`avahi`/`dns-sd`),
  Consul/etcd registration, and cloud private DNS (`Route53`, Cloud DNS, Azure Private DNS).
- [`tls/`](./tls/README.md): Internal cluster mTLS Certificate Authority (`ca.*`) and public ACME
  certificate automation (`acme.*`).
- [`ingress/`](./ingress/README.md): North-south HTTP/TCP/gRPC routing compiled via
  `_lib/networking/netctl/`.
- [`logging/`](./logging/README.md): Structured log shipping via Fluent Bit, Vector, or `syslog`.
- [`metrics/`](./metrics/README.md): Host and component metrics scraping via Prometheus Node
  Exporter or OpenTelemetry Collector.
- [`backup/`](./backup/README.md): Coordinated physical/tenant backups, ZFS/Btrfs CoW snapshots, and
  encrypted S3/GCS/Azure/Restic/Borg/Rclone shipping + point-in-time restore.
- [`maintenance/`](./maintenance/README.md): Automated `cert-renew`, `log-rotate`, `db-vacuum`, and
  `backup-prune` timers across `systemd`, `cron`, `launchd`, and Windows `schtasks`.

## Usage

```sh
./libscript.sh trait list
./libscript.sh trait apply storage --sysroot build/sysroot
./libscript.sh trait apply firewall
./libscript.sh trait verify mesh
./libscript.sh trait teardown ingress
```

```cmd
.\libscript.cmd trait list
.\libscript.cmd trait apply firewall
.\libscript.cmd trait verify storage
```
