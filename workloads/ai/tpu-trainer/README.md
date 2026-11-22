# Cloud TPU Lockstep Trainer (`workloads/ai/tpu-trainer`)

Orchestrates multi-worker Google Cloud TPU VM training jobs via
`workloads/schedulers/tpu_vm.{sh,cmd}`, `workloads/ai/_common/tpu_matrix.{sh,cmd}`, and
`infrastructure/providers/gcp-tpu-vm/cli.{sh,cmd}`.

## Usage

```sh
./libscript.sh tpu-trainer submit workloads/payloads/ai/gcp-tpu-vm/payload.json [--dry-run]
```

## Configuration

| Variable              | Default           | Description                                                                                 |
| --------------------- | ----------------- | ------------------------------------------------------------------------------------------- |
| `TPU_TRAINER_BACKEND` | `jax_native`      | Isolated `/dev/shm` backend (`jax_native`, `maxtext`, `pytorch_native`, `hf_transformers`). |
| `ML_SCRIPT`           | `python train.py` | Lockstep training command run across all TPU workers.                                       |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                           | Default           | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------- | ----------------- | ---------------- |
| `TPU_TRAINER_BACKEND` | ML backend framework initialized in /dev/shm uv virtualenvs across TPU slice workers. | `jax_native`      |                  |
| `ML_SCRIPT`           | Training command executed in lockstep across all TPU slice workers.                   | `python train.py` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
