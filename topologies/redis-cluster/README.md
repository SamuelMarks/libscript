# Tier 3.5 HA Topology Blueprint: `redis-cluster`

## Overview

Turnkey multi-node high-availability topology blueprint for `redis-cluster` orchestrated by
`topologies/engine.sh` and `topologies/engine.cmd`.

## Usage

```sh
./topologies/redis-cluster/cli.sh up
./topologies/redis-cluster/cli.sh status
./topologies/redis-cluster/cli.sh destroy
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
