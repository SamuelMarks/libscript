# Tier 3.5: Topologies & Consensus Choreography (`topologies/`)

## Overview

`topologies/` implements multi-node cluster orchestration, consensus bootstrapping, distributed
lease locking, and split-brain fencing across Tier 3 cloud providers and hypervisors.

## Core Capabilities

- **Deterministic State Machine (`.topology_state.json`)**: Governed by
  `topologies/topology-state.schema.json`, tracking cluster epochs, active leader IDs, per-node
  state transitions (`PENDING` -> `PROVISIONED` -> `SUBSTRATE_READY` -> `CONFIGURED` -> `JOINED` ->
  `DRAINING` -> `FENCED` -> `DESTROYED`), and cloud resource identifiers with atomic
  write-then-rename checkpointing.
- **Distributed Lease Locking (`lock.{sh,cmd}`)**: Prevents concurrent mutations via shared state
  locks in `s3://`, `gs://`, `azure://`, `etcd`, or local lockfiles.
- **Split-Brain Fencing (`fence.{sh,cmd}`)**: Demotes and firewall-isolates unreachable leaders or
  invokes Tier 3 Cloud IaaS APIs (NIC/volume detach or power-off) prior to promoting a replica.
- **Turnkey HA Blueprints**:
  - `postgres-ha/`: PostgreSQL + Patroni + `etcd` consensus + PgBouncer + `netctl` VIP routing.
  - `valkey-cluster/`: Distributed Valkey cluster with slot sharding and automatic failover.
  - `redis-cluster/`: Distributed Redis cluster with Sentinel/Cluster failover.
  - `k0s-ha/`: Multi-control-plane Kubernetes (`k0s`) HA cluster.
  - `minio-distributed/`: Erasure-coded distributed MinIO object storage cluster.
  - `gke-tpu-cluster/`: Multi-pool GKE + TPU node-pool topology.

## Usage

```sh
./libscript.sh topology up topologies/postgres-ha/topology.json
./libscript.sh topology status topologies/postgres-ha/topology.json
./libscript.sh topology failover topologies/postgres-ha/topology.json node-follower-1
./libscript.sh topology destroy topologies/postgres-ha/topology.json
```
