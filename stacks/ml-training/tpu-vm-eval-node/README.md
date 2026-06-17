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

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.
