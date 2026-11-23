# Tier 5 (`T5`) Workload Payload: `gke-tpu-cluster-workload` (`workloads/payloads/ai/jax-tpu-multi-slice-training/`)

## Overview

Multi-slice TPU workload template scheduled onto a T5 GKE TPU cluster topology.

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `ai-training`
- **Artifact Format**: `oci-image` (`gcr.io/cloud-tpu-v2-images/jax-ai-image:latest`)
- **Resource Profile**: `cpu_cores=32`, `memory_mb=131072`, `tpu_accelerator_type=v4-8`,
  `tpu_topology=2x2x1`, `tpu_slice_count=2`
- **Scaling & Gang Policy**: `replicas=2`, `strategy=Recreate`, `gang_scheduling=true`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/ai/jax-tpu-multi-slice-training/payload.json --scheduler tpu_vm

# Submit to tpu_vm (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/ai/jax-tpu-multi-slice-training/payload.json --scheduler tpu_vm

# Inspect status and stream logs
./libscript.sh payload status gke-tpu-cluster-workload --scheduler tpu_vm
./libscript.sh payload logs gke-tpu-cluster-workload --scheduler tpu_vm
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\jax-tpu-multi-slice-training\payload.json --scheduler tpu_vm
.\libscript.cmd payload submit workloads\payloads\ai\jax-tpu-multi-slice-training\payload.json --scheduler tpu_vm
```
