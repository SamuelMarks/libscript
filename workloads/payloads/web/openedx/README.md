# Tier 5 (`T5`) Workload Payload: `openedx` (`workloads/payloads/web/openedx/`)

## Overview

Single-process or constellation-deployable Open edX LMS, Studio/CMS, and Celery learning workload.

Defined in [`payload.json`](./payload.json) and validated against
[`../../../schemas/payload.schema.json`](../../../schemas/payload.schema.json).

## Specification Summary

- **Workload Type**: `unikernel`
- **Artifact Format**: `unikernel-binary` (`-`)
- **Resource Profile**: `cpu_cores=4`, `memory_mb=8192`
- **Scaling & Gang Policy**: `replicas=2`, `strategy=RollingUpdate`, `gang_scheduling=false`

## Usage

```sh
# Compile into native scheduler manifests without executing
./libscript.sh payload compile workloads/payloads/web/openedx/payload.json --scheduler kubernetes

# Submit to kubernetes (or swap --scheduler for kubernetes, nomad, mesos, slurm_ray, microvm, native)
./libscript.sh payload submit workloads/payloads/web/openedx/payload.json --scheduler kubernetes

# Inspect status and stream logs
./libscript.sh payload status openedx --scheduler kubernetes
./libscript.sh payload logs openedx --scheduler kubernetes
```

```cmd
.\libscript.cmd payload compile workloads\payloads\web\openedx\payload.json --scheduler kubernetes
.\libscript.cmd payload submit workloads\payloads\web\openedx\payload.json --scheduler kubernetes
```

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `workloads/apps/openedx`
- `_lib/unikernels/nanos`
