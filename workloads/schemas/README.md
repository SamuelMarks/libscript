# Tier 5 (`T5`) Workload, Stack & AI Schemas (`workloads/schemas/`)

## Overview

`workloads/schemas/` houses the JSON Schema (Draft 2020-12) specifications for `T5` declarative
stacks, scheduler-agnostic payloads, and distributed AI/TPU jobs.

## Schemas

- **`libscript.schema.json`**: Declarative multi-service stack, database, service, and `netctl`
  ingress manifest contract (`libscript.json`, symlinked from root `libscript.schema.json`).
- **`payload.schema.json`**: Universal workload payload specification (`artifact`, `resources`,
  `scaling`, `ports`, `health_check`, `traits`) consumed by `workloads/schedulers/*`.
- **`workload-common.schema.json`**: Shared resource request, accelerator, port, and health-probe
  definitions reused across payloads and constellations.
- **`ml-workload.schema.json`**: Distributed ML training, fine-tuning, evaluation, and serving job
  specification consumed by `workloads/ai/actions.{sh,cmd}`.
- **`tpu-matrix.schema.json`**: Multi-framework TPU benchmark matrix configuration schema consumed
  by `workloads/ai/_common/tpu_matrix.{sh,cmd}`.
