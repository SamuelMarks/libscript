# GCP Cloud TPU VM Component (`gcp/tpu-vm`)

## Overview

This component provides a streamlined command-line interface for provisioning, managing, and
connecting to Google Cloud TPU VMs. It has been specifically extended to support the strict
constraints and availability challenges of the **TPU Research Cloud (TFRC)**.

## Usage

You can use the component by running:

```sh
libscript gcp/tpu-vm <action> <name> [args...]
```

### Supported Actions

- `create <name>`: Provisions one or more TPU VMs. Respects `TPU_COUNT` for multi-node provisioning.
- `delete <name> [--all]`: Deletes the TPU VM(s), Queued Resource requests (if any), and attached
  data disks.
- `start <name> [--all]`: Starts stopped TPU VM(s).
- `stop <name> [--all]`: Stops running TPU VM(s).
- `ssh <name> [--detached] [--forward-port <local>:<remote>] [--all-workers] [command]`: Connects to
  the TPU VM.
- `scp <name> <src> <dest> [--all-workers]`: Securely copies files to/from the TPU VM.
- `status <name> [--all]`: Polls and reports the state of the TPU VM or its Queued Resource request.

## TFRC Configuration Examples

### Standard TFRC `v2-8` Preemptible Setup

Most TFRC grants provide a pool of preemptible `v2-8` or `v3-8` devices.

```sh
export GCP_PROJECT_ID="your-project-id"
export TPU_ZONE="us-central1-f"
export TPU_ACCELERATOR_TYPE="v2-8"
export TPU_VERSION="tpu-ubuntu2204-base"
export TPU_SCHEDULING_TYPE="preemptible"

# Provision the instance
libscript gcp/tpu-vm create my-tpu
```

### TFRC Pod Slice Setup (`v3-32`)

For large-scale distributed training, you may be granted a Pod slice (e.g., `v3-32`), which consists
of multiple interconnected workers.

```sh
export GCP_PROJECT_ID="your-project-id"
export TPU_ZONE="europe-west4-a"
export TPU_ACCELERATOR_TYPE="v3-32"
export TPU_VERSION="tpu-ubuntu2204-base"

# Provision the Pod slice
libscript gcp/tpu-vm create my-pod
```

#### Multi-Worker Distributed Training (Jax/PyTorch)

When working with Pod slices, you often need to execute commands or copy datasets across all workers
simultaneously.

Use the `--all-workers` flag to perform actions across the entire pod:

```sh
# Copy a training script to all workers in the pod
libscript gcp/tpu-vm scp my-pod ./train.py my-pod:/tmp/train.py --all-workers

# Execute the training script synchronously across all workers
libscript gcp/tpu-vm ssh my-pod "python3 /tmp/train.py" --all-workers
```

## "Out of capacity" Mitigation: Queued Resources API

Because TFRC relies on spare research capacity, standard `create` requests frequently fail with
`429` or `503` "out of resources" errors.

To mitigate this, you can enable the **Queued Resources API**. This places your request in a queue,
and Google will automatically provision the TPUs as soon as TFRC capacity opens up.

```sh
export TPU_USE_QUEUED_RESOURCE="true"
export TPU_SCHEDULING_TYPE="preemptible"

# This will submit a queued request named "my-model-qr"
libscript gcp/tpu-vm create my-model

# You can poll the status (ACCEPTED, PROVISIONING, ACTIVE, FAILED)
libscript gcp/tpu-vm status my-model

# Once finished, delete the resource and the queue request to free up your quota
libscript gcp/tpu-vm delete my-model
```

## Environment Variables

<!-- BEGIN_VARS -->
| Variable | Description | Default | Aliases/Examples |
|---|---|---|---|
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native). | `libscript_native` |  |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows (winget, choco). | `winget` |  |
| `LIBSCRIPT_LOG_LEVEL` | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR). | `1` |  |
| `LIBSCRIPT_LOG_FORMAT` | Output format for logs (text, json). | `text` |  |
| `LIBSCRIPT_LOG_FILE` | File to write logs to (in addition to standard output). | `none` |  |
| `LIBSCRIPT_SERVICE_NAME` | Overrides the default service name. | `none` |  |
| `DOWNLOAD_DIR` | Directory where downloads are stored. | `none` |  |
| `FORMAT` | Output format (e.g., json, text). | `none` |  |
| `LIBSCRIPT_CACHE_DIR` | Directory where cached files are stored. | `none` |  |
| `LIBSCRIPT_LOG_DRIVER` | Logging driver to use (e.g., fluentd). | `none` |  |
| `LOGS_DIR` | Directory where logs should be stored. | `none` |  |
| `VAULT_TOKEN` | Token for HashiCorp Vault authentication. | `none` |  |
| `PREFIX` | Installation prefix. | `none` |  |
| `SERVE_FROM` | Base directory or context path for the service. | `none` |  |
| `LIBSCRIPT_LOG_HOST` | Host for remote logging. | `none` |  |
| `LIBSCRIPT_VERSION` | Specifies the version of the package to use. | `none` |  |
| `LIBSCRIPT_LOG_PORT` | Port for remote logging. | `none` |  |
| `TPU_ZONE` | GCP Zone for TPU provisioning | `us-central2-b` |  |
| `TPU_ACCELERATOR_TYPE` | Type of TPU accelerator (e.g. v4-8) | `v4-8` |  |
| `TPU_VERSION` | TPU VM OS version | `tpu-ubuntu2204-base` |  |
| `GCP_PROJECT_ID` | GCP Project ID | `none` |  |
| `XPK_CLUSTER_NAME` | Name for the XPK GKE cluster | `none` |  |
| `TPU_TENSOR_PARALLEL_SIZE` | Tensor parallel size for TPU serving | `1` |  |
| `MODEL_NAME` | HuggingFace model string to serve | `your-org/your-model-name` |  |
| `WORKLOAD_NAME` | Name of the XPK workload | `none` |  |
| `JETSTREAM_IMAGE` | Docker image for JetStream TPU inference | `none` |  |
| `TPU_VM_VERSION` | Specific version of tpu-vm to install. Can be a numeric version or an alias. | `latest` | latest, stable |
| `TPU_VM_INSTALL_METHOD` | How to install TPU-VM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise' or 'asdf' defers to third-party tools. | `libscript_native` |  |
| `TPU_SCHEDULING_TYPE` | Scheduling type for the TPU VM (on-demand, spot, or preemptible). | `on-demand` |  |
| `TPU_ACCELERATOR_TYPE` | Type of TPU accelerator (e.g., v2-8, v3-8, v4-8, v3-32). Defines the hardware topology. | `none` |  |
| `TPU_ZONE` | GCP Zone for TPU provisioning. Must match the specific TFRC granted zone if using TFRC. | `none` |  |
| `TPU_VERSION` | TPU VM OS version (e.g., tpu-ubuntu2204-base). Ensure compatibility with TPU_ACCELERATOR_TYPE. | `tpu-ubuntu2204-base` |  |
| `TPU_COUNT` | Number of independent TPU VMs to provision. Useful for multi-node provisioning. | `1` |  |
| `TPU_USE_QUEUED_RESOURCE` | Whether to use the Queued Resources API for provisioning to better handle capacity errors. | `none` |  |
| `TPU_DATA_DISK_SIZE` | Size of the persistent data disk in GB (optional). | `none` |  |
| `TPU_DATA_DISK_TYPE` | Type of the persistent data disk (e.g., pd-balanced). | `pd-balanced` |  |
<!-- END_VARS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
