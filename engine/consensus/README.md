# Tier 0 (`T0`) Consensus & Split-Brain Fencing (`engine/consensus/`)

## Overview

`engine/consensus/` implements the `T0` distributed lease-locking and split-brain fencing state
machine shared by `T4` cluster substrates (`infrastructure/clusters/`) and `T5` stateful service
constellations (`workloads/constellations/`). Placing consensus primitives in `T0` guarantees that
both infrastructure cluster substrates and higher-level application constellations can coordinate
quorum transitions without upward or circular cross-tier imports.

## Modules

- **`lock.{sh,cmd}`**: Distributed lease acquisition, renewal, heartbeat verification, and
  compare-and-swap epoch advancement governed by `engine/schemas/consensus-state.schema.json` and
  `engine/schemas/consensus-common.schema.json`.
- **`fence.{sh,cmd}`**: Deterministic STONITH / split-brain fencing actuator supporting
  `cloud-api-poweroff`, `vpc-nic-detach`, `storage-lease-revoke`, and node quarantine before
  promoting a new primary replica.

## Usage

```sh
# Acquire or inspect a quorum lease and fence a partitioned node
./engine/consensus/lock.sh --help
./engine/consensus/fence.sh --help
```

```cmd
.\engine\consensus\lock.cmd --help
.\engine\consensus\fence.cmd --help
```
