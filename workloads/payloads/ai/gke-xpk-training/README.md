# Tier 5 (`T5`) Workload Payload: `gke-xpk-training` (`workloads/payloads/ai/gke-xpk-training/`)

## Overview

Distributed AI/ML gang-scheduled training workload executed on Google Kubernetes Engine (GKE)
TPU/GPU slices via XPK.

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `ai-training`
- **Artifact Format**: `oci-image` (`gcr.io/cloud-tpu-v2-images/jax-ai-image:latest`)
- **Resource Profile**: `cpu_cores=32`, `memory_mb=131072`, `tpu_accelerator_type=v4-8`,
  `tpu_topology=2x2x1`, `tpu_slice_count=1`
- **Scaling & Gang Policy**: `replicas=1`, `strategy=Recreate`, `gang_scheduling=true`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/ai/gke-xpk-training/payload.json --scheduler xpk

# Submit to xpk (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/ai/gke-xpk-training/payload.json --scheduler xpk

# Inspect status and stream logs
./libscript.sh payload status gke-xpk-training --scheduler xpk
./libscript.sh payload logs gke-xpk-training --scheduler xpk
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\gke-xpk-training\payload.json --scheduler xpk
.\libscript.cmd payload submit workloads\payloads\ai\gke-xpk-training\payload.json --scheduler xpk
```
