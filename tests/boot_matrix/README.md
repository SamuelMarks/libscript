# Hypervisor Boot & Service Readiness Smoke Matrix (`tests/boot_matrix/`)

## Overview

Validates direct-boot kernel bundles (`QEMU`, `Firecracker`, `bhyve`, `Solo5`) across Linux,
FreeBSD, illumos, Unikraft, Nanos/Ops, OSv, Rumprun, and MirageOS, and probes live service readiness
on `redis` (`6379` `+PONG`), `postgres` (`5432` `pg_isready` / `SELECT 1`), and `openedx`
(`8000/heartbeat` & `8001`).

## Usage

```sh
./tests/boot_matrix/run_boot_smoke.sh
./tests/boot_matrix/run_boot_smoke.sh --probe-live --host 127.0.0.1
```
