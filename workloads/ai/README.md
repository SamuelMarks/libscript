# Tier 5 (`T5`) Distributed AI/ML Training & Serving Actions (`workloads/ai/`)

## Overview

`workloads/ai/` implements `T5` distributed machine learning training, LLM inference routing, model
evaluation, and hardware-accelerated TPU/GPU benchmark orchestration invoked via
`./libscript.sh <train-ml|serve-ml|eval-ml|benchmark-ml>` (`workloads/ai/actions.{sh,cmd}`).

## Submodules

- **`actions.{sh,cmd}`**: Top-level dispatcher for `train-ml`, `serve-ml`, `eval-ml`, and
  `benchmark-ml` CLI verbs validated against `workloads/schemas/ml-workload.schema.json`.
- [`tpu-trainer/`](./tpu-trainer/README.md): Multi-worker lockstep Cloud TPU training orchestrator
  integrating 4-role regional GCS storage (`traits/storage/gcs_ml.*`), `gcsfuse`, and TensorBoard.
- [`inference-router/`](./inference-router/README.md): Unified OpenAI-compatible LLM serving gateway
  routing across `vLLM`, `JetStream`, MaxEngine, Triton, and `Ollama` backends.
- [`_common/`](./_common/README.md): Shared multi-framework Cloud TPU matrix runner
  (`tpu_matrix.{sh,cmd}`) and default topology profiles (`tpu_matrix_defaults.json`).
