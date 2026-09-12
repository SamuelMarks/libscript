# ml-training/tpu-vm-eval-node

## Overview

This stack automates the provisioning of a single TPU VM optimized for heavy, long-running ML
workloads.

It accomplishes the following:

1. **Persistent Disk:** Attaches an external disk for large local datasets (e.g. HuggingFace cache).
2. **Object Storage:** Automates the installation and mounting of `gcsfuse` for direct checkpoint
   streaming to/from Google Cloud Storage.
3. **Execution Resilience:** Runs your training command inside a detached `tmux` session, surviving
   local machine disconnects.
4. **Observability:** Installs TensorBoard and automatically tunnels the port (6006) back to your
   local machine via SSH port forwarding.

## Usage

Refer to the component's setup and deploy scripts for specific operations.

```bash
# Provision the infrastructure
./stacks/ml-training/tpu-vm-eval-node/setup.sh

# Deploy the ML loop
export BUCKET_NAME="gs://my-bucket"
export ML_SCRIPT="python -m my_train_script"
./stacks/ml-training/tpu-vm-eval-node/deploy.sh
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                            | Default           | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------- | ----------------- | ---------------- |
| `TPU_NAME`             | Name of the TPU VM instance                                            | `ml-eval-node`    |                  |
| `GCP_PROJECT_ID`       | Google Cloud Project ID where the TPU VM is provisioned                | ``                |                  |
| `TPU_ZONE`             | Google Cloud Zone for the TPU VM (e.g. us-central2-b)                  | ``                |                  |
| `TPU_ACCELERATOR_TYPE` | TPU accelerator version and topology (e.g. v4-8)                       | `v4-8`            |                  |
| `TPU_DATA_DISK_SIZE`   | Persistent data disk size in GB attached to the TPU VM                 | `200`             |                  |
| `BUCKET_NAME`          | GCS bucket mounted via Cloud Storage FUSE for datasets and checkpoints | ``                |                  |
| `ML_SCRIPT`            | Evaluation or training command to execute on the TPU VM                | `python train.py` |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
