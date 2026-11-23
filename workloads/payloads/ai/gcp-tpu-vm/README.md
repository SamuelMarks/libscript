# Tier 5 (`T5`) Workload Payload: `gcp-tpu-vm-workload` (`workloads/payloads/ai/gcp-tpu-vm/`)

## Overview

AI training and evaluation workload wrapper executing over T4 GCP Cloud TPU VMs with gcsfuse and
TensorBoard.

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `ai-training`
- **Artifact Format**: `libscript-component` (`infrastructure/providers/gcp-tpu-vm`)
- **Resource Profile**: `cpu_cores=16`, `memory_mb=65536`, `tpu_accelerator_type=v4-8`,
  `tpu_topology=2x2x1`, `tpu_slice_count=1`
- **Scaling & Gang Policy**: `replicas=1`, `strategy=Recreate`, `gang_scheduling=true`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/ai/gcp-tpu-vm/payload.json --scheduler tpu_vm

# Submit to tpu_vm (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/ai/gcp-tpu-vm/payload.json --scheduler tpu_vm

# Inspect status and stream logs
./libscript.sh payload status gcp-tpu-vm-workload --scheduler tpu_vm
./libscript.sh payload logs gcp-tpu-vm-workload --scheduler tpu_vm
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\gcp-tpu-vm\payload.json --scheduler tpu_vm
.\libscript.cmd payload submit workloads\payloads\ai\gcp-tpu-vm\payload.json --scheduler tpu_vm
```
