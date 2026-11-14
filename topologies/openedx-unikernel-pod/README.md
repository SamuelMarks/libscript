# Open edX Decomposed Unikernel & MicroVM Appliance Pod (`openedx-unikernel-pod`)

## Overview

Decomposes the multi-daemon Open edX learning platform across specialized single-process unikernels
(`Unikraft`, `Nanos/Ops`, `OSv`, `MirageOS`) and persistent datastore appliances connected over an
isolated `172.30.0.0/24` virtual bridge:

- **Ingress & Static MFEs**: `caddy` unikernel serving pre-built Open edX MFE bundles from
  ROMFS/EROFS.
- **Cache Tier**: `redis` single-process unikernel with AOF persistence (`6379`).
- **LMS / Studio / Celery Workers**: Nanos/Ops or OSv Python/Gunicorn & Celery appliances mounting
  read-only `.venv` + `edx-platform` EROFS volumes.
- **Datastore & Search Tiers**: `mysql`, `ferretdb` + `postgres` (MongoDB wire-compatible
  modulestore), and `meilisearch` on OSv/Nanos persistent volumes.

## Usage

```sh
./topologies/openedx-unikernel-pod/cli.sh status
./libscript.sh build-image --profile=profiles/unikernel-openedx-pod.json --kernel=nanos --format=direct-kernel --dry-run
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
