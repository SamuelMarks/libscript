# Tier 5 (`T5`) Workload Payload: `ollama` (`workloads/payloads/ai/ollama/`)

## Overview

Standalone local and edge large language model serving runtime powered by _lib/utilities/ollama.

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `ai-inference`
- **Artifact Format**: `libscript-component` (`_lib/utilities/ollama`)
- **Resource Profile**: `cpu_cores=4`, `memory_mb=16384`, `gpu_count=0`
- **Scaling & Gang Policy**: `replicas=1`, `strategy=RollingUpdate`, `gang_scheduling=false`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/ai/ollama/payload.json --scheduler native

# Submit to native (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/ai/ollama/payload.json --scheduler native

# Inspect status and stream logs
./libscript.sh payload status ollama --scheduler native
./libscript.sh payload logs ollama --scheduler native
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\ollama\payload.json --scheduler native
.\libscript.cmd payload submit workloads\payloads\ai\ollama\payload.json --scheduler native
```
