# Tier 5 (`T5`): Stateful High-Availability Constellations (`workloads/constellations/`)

## Overview

`workloads/constellations/` orchestrates multi-node stateful database, cache, object-storage,
unikernel, edge, and enterprise web constellations governed by `constellation.schema.json`. It pairs
`T0` distributed lease locking (`engine/consensus/lock.{sh,cmd}`) and automated split-brain fencing
(`engine/consensus/fence.{sh,cmd}`) with live `Plane A` traits (`traits/mesh/`, `traits/tls/`,
`traits/ingress/`, `traits/backup/`) atop `T4` cloud providers or cluster substrates
(`infrastructure/clusters/`).

> **Note:** Underlying compute/container cluster substrates (`gke-tpu-cluster`, `k0s-ha`,
> `k8s-marathon-paas`, `kubernetes-thw`, `mesos-marathon-ha`) live in `T4`
> [`infrastructure/clusters/`](../../infrastructure/clusters/README.md) and are managed via
> `./libscript.sh cluster <verb> ...`.

## Constellation Blueprints

- [`postgres-ha/`](./postgres-ha/README.md): Patroni + etcd Raft quorum + PostgreSQL streaming
  replication + PgBouncer connection pooling with fenced leader failover.
- [`redis-cluster/`](./redis-cluster/README.md): 6-node Redis Cluster (16384 hash slots) + Sentinel
  quorum over WireGuard mesh peering.
- [`valkey-cluster/`](./valkey-cluster/README.md): High-availability Valkey cluster with automated
  shard rebalancing and replica promotion.
- [`minio-distributed/`](./minio-distributed/README.md): Erasure-coded multi-node S3-compatible
  MinIO object storage constellation.
- [`openedx-ha/`](./openedx-ha/README.md): Multi-node Open edX production constellation separating
  stateless LMS/CMS/MFE/Celery tiers from HA MariaDB, MongoDB, Redis, and Meilisearch quorums.
- [`openedx-unikernel-pod/`](./openedx-unikernel-pod/README.md): 8-appliance single-process
  unikernel constellation (OSv / Nanos / Unikraft) with cloud Marketplace offer packaging.
- [`iot-mqtt-edge-pod/`](./iot-mqtt-edge-pod/README.md): Edge MQTT broker + Zephyr/FreeRTOS sensor
  fleet + time-series ingestion constellation.
- [`unikernel_pod/`](./unikernel_pod/README.md): Composable multi-unikernel pod orchestrator over
  isolated TAP bridges and `netctl` ingress.

## Usage

```sh
./libscript.sh constellation up workloads/constellations/postgres-ha/topology.json
./libscript.sh constellation status workloads/constellations/postgres-ha/topology.json
./libscript.sh constellation scale workloads/constellations/postgres-ha/topology.json pg-replicas=4
./libscript.sh constellation failover workloads/constellations/postgres-ha/topology.json node-follower-1
./libscript.sh constellation destroy workloads/constellations/postgres-ha/topology.json
```

```cmd
.\libscript.cmd constellation up workloads\constellations\postgres-ha\topology.json
.\libscript.cmd constellation status workloads\constellations\postgres-ha\topology.json
.\libscript.cmd constellation failover workloads\constellations\postgres-ha\topology.json node-follower-1
.\libscript.cmd constellation destroy workloads\constellations\postgres-ha\topology.json
```
