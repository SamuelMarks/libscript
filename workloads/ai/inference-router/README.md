# Accelerator Inference Router (`workloads/ai/inference-router`)

Routes declarative model-serving workloads (`vllm`, `jetstream`, `ollama`) onto Cloud TPU slices,
GKE XPK clusters, or Kubernetes via `workloads/engine.{sh,cmd}`.

## Usage

```sh
./libscript.sh inference-router submit workloads/payloads/ai/vllm/payload.json [--dry-run]
```

## Configuration

| Variable              | Default  | Description                                                 |
| --------------------- | -------- | ----------------------------------------------------------- |
| `INFERENCE_SCHEDULER` | `tpu_vm` | Target scheduler (`tpu_vm`, `xpk`, `kubernetes`, `native`). |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                              | Default  |
| :-------------------- | :--------------------------------------------------------------------------------------- | :------- |
| `INFERENCE_SCHEDULER` | Target scheduler driver used for inference deployment (tpu_vm, xpk, kubernetes, native). | `tpu_vm` |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
