# Tier 5 (`T5`): Workloads, Application Stacks & Stateful Constellations (`workloads/`)

## Overview

`workloads/` is the top compositional tier (`T5`) of LibScript. It consumes `T1`/`T2` atomic
components (`_lib/`), `T3` synthesized images/packages (`synthesis/`), `T4` cloud infrastructure and
cluster substrates (`infrastructure/`), and live `Plane A` node traits (`traits/`) to deploy
full-stack applications, schedule distributed batch/AI payloads, and choreograph stateful
High-Availability (HA) service constellations.

## Subsystems

- [`apps/`](./apps/README.md): Turnkey multi-service web, LMS, ERP, e-commerce, and worker stacks
  (`openedx`, `wordpress`, `woocommerce`, `nextcloud`, `odoo`, `drupal`, `joomla`, `magento`,
  `prestashop`, `phpbb`, `jupyterhub`, `celery`, `firecrawl`, `serve-actix-diesel-auth-scaffold`).
- [`constellations/`](./constellations/README.md): Multi-node stateful HA constellations
  (`postgres-ha`, `redis-cluster`, `valkey-cluster`, `minio-distributed`, `openedx-ha`,
  `openedx-unikernel-pod`, `iot-mqtt-edge-pod`, `unikernel_pod`) backed by `T0`
  `engine/consensus/{lock,fence}.{sh,cmd}`.
- [`payloads/`](./payloads/README.md): Declarative scheduler-agnostic `payload.json` workloads
  across `ai/` (`vllm`, `jetstream`, `ollama`, `gcp-gpu-vm`, `gcp-tpu-vm`, `gke-xpk-training`,
  `gke-xpk-inference`, `jax-tpu-multi-slice-training`) and `web/` (`openedx`).
- [`schedulers/`](./schedulers/README.md): Universal payload translation drivers (`kubernetes`,
  `nomad`, `mesos`, `native`, `microvm`, `rtos_firmware`, `slurm_ray`, `tpu_vm`, `xpk`).
- [`ai/`](./ai/README.md): Distributed ML training (`train-ml`), inference (`serve-ml`), evaluation
  (`eval-ml`), benchmarking (`benchmark-ml`), `tpu-trainer`, `inference-router`, and `tpu_matrix`.
- [`services/`](./services/README.md): Local and remote `libscript.json` service lifecycle and
  deployment (`start`, `stop`, `restart`, `status`, `health`, `logs`, `up`, `down`, `deploy`,
  `deploy-remote`).
- [`schemas/`](./schemas/README.md): `T5` JSON Schemas (`libscript.schema.json`,
  `payload.schema.json`, `workload-common.schema.json`, `ml-workload.schema.json`,
  `tpu-matrix.schema.json`).

## Usage

```sh
# Compile or submit declarative payloads to any T5 scheduler
./libscript.sh payload compile workloads/payloads/ai/vllm/payload.json --scheduler kubernetes
./libscript.sh payload submit workloads/payloads/ai/gke-xpk-training/payload.json --scheduler xpk
./libscript.sh payload status vllm-serving --scheduler native

# Orchestrate stateful HA service constellations
./libscript.sh constellation up workloads/constellations/postgres-ha/topology.json
./libscript.sh constellation status workloads/constellations/postgres-ha/topology.json
```

```cmd
.\libscript.cmd payload compile workloads\payloads\ai\vllm\payload.json --scheduler kubernetes
.\libscript.cmd constellation up workloads\constellations\postgres-ha\topology.json
```
