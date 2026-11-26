# Tier 5 (`T5`) Workload Payload: `jetstream` (`workloads/payloads/ai/jetstream/`)

## Overview

Memory- and throughput-optimized XLA/TPU and GPU LLM inference engine (Google JetStream).

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `ai-inference`
- **Artifact Format**: `oci-image`
  (`us-docker.pkg.dev/cloud-tpu-images/inference/jetstream-http:latest`)
- **Resource Profile**: `cpu_cores=16`, `memory_mb=65536`, `tpu_accelerator_type=v5litepod-8`,
  `tpu_topology=2x4`, `tpu_slice_count=1`
- **Scaling & Gang Policy**: `replicas=1`, `strategy=RollingUpdate`, `gang_scheduling=true`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/ai/jetstream/payload.json --scheduler native

# Submit to native (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/ai/jetstream/payload.json --scheduler native

# Inspect status and stream logs
./libscript.sh payload status jetstream --scheduler native
./libscript.sh payload logs jetstream --scheduler native
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\jetstream\payload.json --scheduler native
.\libscript.cmd payload submit workloads\payloads\ai\jetstream\payload.json --scheduler native
```

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/app-servers/jetstream`
- `_lib/languages/python`
