# Tier 5 (`T5`) Workload Payload: `gcp-gpu-vm-workload` (`workloads/payloads/ai/gcp-gpu-vm/`)

## Overview

CUDA-accelerated model serving and training workload executing on T4 GCP GPU VMs.

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `ai-inference`
- **Artifact Format**: `oci-image` (`vllm/vllm-openai:latest`)
- **Resource Profile**: `cpu_cores=8`, `memory_mb=32768`, `gpu_type=nvidia-tesla-t4`, `gpu_count=1`
- **Scaling & Gang Policy**: `replicas=1`, `strategy=RollingUpdate`, `gang_scheduling=false`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/ai/gcp-gpu-vm/payload.json --scheduler native

# Submit to native (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/ai/gcp-gpu-vm/payload.json --scheduler native

# Inspect status and stream logs
./libscript.sh payload status gcp-gpu-vm-workload --scheduler native
./libscript.sh payload logs gcp-gpu-vm-workload --scheduler native
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\gcp-gpu-vm\payload.json --scheduler native
.\libscript.cmd payload submit workloads\payloads\ai\gcp-gpu-vm\payload.json --scheduler native
```
