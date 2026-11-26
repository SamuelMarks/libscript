# Tier 5 (`T5`) Workload Payload: `gke-xpk-inference` (`workloads/payloads/ai/gke-xpk-inference/`)

## Overview

High-throughput distributed LLM inference serving workload deployed onto GKE TPU slices via XPK.

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `ai-inference`
- **Artifact Format**: `oci-image` (`us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest`)
- **Resource Profile**: `cpu_cores=16`, `memory_mb=65536`, `tpu_accelerator_type=v4-8`,
  `tpu_topology=2x2x1`, `tpu_slice_count=1`
- **Scaling & Gang Policy**: `replicas=1`, `strategy=RollingUpdate`, `gang_scheduling=true`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/ai/gke-xpk-inference/payload.json --scheduler xpk

# Submit to xpk (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/ai/gke-xpk-inference/payload.json --scheduler xpk

# Inspect status and stream logs
./libscript.sh payload status gke-xpk-inference --scheduler xpk
./libscript.sh payload logs gke-xpk-inference --scheduler xpk
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\gke-xpk-inference\payload.json --scheduler xpk
.\libscript.cmd payload submit workloads\payloads\ai\gke-xpk-inference\payload.json --scheduler xpk
```

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/app-servers/vllm`
- `_lib/schedulers/kubernetes`
