# T5 HA Topology Blueprint: `postgres-ha`

## Overview

Turnkey multi-node high-availability topology blueprint for `postgres-ha` orchestrated by
`workloads/constellations/engine.sh` and `workloads/constellations/engine.cmd`.

## Usage

```sh
./workloads/constellations/postgres-ha/cli.sh up
./workloads/constellations/postgres-ha/cli.sh status
./workloads/constellations/postgres-ha/cli.sh destroy
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/databases/postgres`
- `_lib/databases/etcd`
- `_lib/networking/netctl`
