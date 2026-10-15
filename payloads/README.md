# Tier 4: Payloads & Declarative Workloads (`payloads/`)

## Overview

`payloads/` houses declarative application, batch, unikernel, and distributed AI/ML workload
definitions governed by `payloads/payload.schema.json`. Unlike Tier 1 (`_lib/`), which installs
binaries and manages local versioned sandboxes, or Tier 3 (`_lib/cloud-providers/`), which
provisions raw virtual machines and cloud networks, Tier 4 defines **what workload runs** and **what
resources, accelerators, and logical tenant bindings it requires**, remaining completely decoupled
from the underlying cluster scheduler.

## Directory Layout

- `payload.schema.json`: JSON Schema Draft 2020-12 contract validating all Tier 4 workload
  specifications with 100% property description coverage.
- `schedulers/`: Technology-agnostic translation drivers (`kubernetes`, `nomad`, `mesos`, `native`,
  `microvm`, `xpk`, `slurm_ray`) that compile a single `payload.json` into target-native execution
  manifests.
- `ai/`: Ephemeral and long-running AI/ML training and inference workloads (`gke-xpk-training`,
  `gke-xpk-inference`, `vllm`, `jetstream`, `ollama`, `gcp-tpu-vm`, `gcp-gpu-vm`,
  `gke-tpu-cluster`).

## Usage

```sh
./libscript.sh payload compile payloads/ai/vllm/payload.json --scheduler kubernetes
./libscript.sh payload submit payloads/ai/gke-xpk-training/payload.json --scheduler xpk
./libscript.sh payload status vllm-serving --scheduler native
```
