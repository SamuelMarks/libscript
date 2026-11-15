# Accelerator Inference Router (`_lib/ai-serving/inference-router`)

Routes declarative model-serving workloads (`vllm`, `jetstream`, `ollama`) onto Cloud TPU slices,
GKE XPK clusters, or Kubernetes via `payloads/engine.{sh,cmd}`.

## Usage

```sh
./libscript.sh inference-router submit payloads/ai/vllm/payload.json [--dry-run]
```

## Configuration

| Variable              | Default  | Description                                                 |
| --------------------- | -------- | ----------------------------------------------------------- |
| `INFERENCE_SCHEDULER` | `tpu_vm` | Target scheduler (`tpu_vm`, `xpk`, `kubernetes`, `native`). |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                              | Default  | Aliases/Examples |
| --------------------- | ---------------------------------------------------------------------------------------- | -------- | ---------------- |
| `INFERENCE_SCHEDULER` | Target scheduler driver used for inference deployment (tpu_vm, xpk, kubernetes, native). | `tpu_vm` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
