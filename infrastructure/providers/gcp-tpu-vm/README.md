# GCP Cloud TPU VM Component (`gcp-tpu-vm`)

## Overview

This component provides a streamlined command-line interface for provisioning, managing, and
connecting to Google Cloud TPU VMs. It has been specifically extended to support the strict
constraints and availability challenges of the **TPU Research Cloud (TFRC)**.

## Usage

You can use the component by running:

```sh
libscript gcp-tpu-vm <action> <name> [args...]
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
libscript gcp-tpu-vm create my-tpu
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
libscript gcp-tpu-vm create my-pod
```

#### Multi-Worker Distributed Training (Jax/PyTorch)

When working with Pod slices, you often need to execute commands or copy datasets across all workers
simultaneously.

Use the `--all-workers` flag to perform actions across the entire pod:

```sh
# Copy a training script to all workers in the pod
libscript gcp-tpu-vm scp my-pod ./train.py my-pod:/tmp/train.py --all-workers

# Execute the training script synchronously across all workers
libscript gcp-tpu-vm ssh my-pod "python3 /tmp/train.py" --all-workers
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
libscript gcp-tpu-vm create my-model

# You can poll the status (ACCEPTED, PROVISIONING, ACTIVE, FAILED)
libscript gcp-tpu-vm status my-model

# Once finished, delete the resource and the queue request to free up your quota
libscript gcp-tpu-vm delete my-model
```

## Environment Variables

<!-- BEGIN_VARS -->

| Variable                             | Description                                                                                                                                                       | Default               | Aliases/Examples         |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ------------------------ |
| `LIBSCRIPT_TFRC_CONFIG`              | Explicit filesystem path to the user-supplied TFRC zero-cost policy JSON file validated against engine/schemas/tfrc-policy.schema.json.                           | `none`                |                          |
| `LIBSCRIPT_TFRC_STRICT`              | Flag (0 or 1) enforcing zero-cost TFRC guardrails (blocking GKE, Persistent Disks, static IPs, and non-matching GCS regions).                                     | `0`                   |                          |
| `LIBSCRIPT_TFRC_STORAGE_MODE`        | Artifact and code transfer transport mode under TFRC enforcement (ssh default, or verified same_region_gcs).                                                      | `ssh`                 |                          |
| `LIBSCRIPT_TFRC_MAX_TTL_MINUTES`     | Maximum time-to-live in minutes armed on provisioned TPU VM workers via the dead-man's switch timer.                                                              | `180`                 |                          |
| `LIBSCRIPT_TFRC_SHM_MIN_FREE_GB`     | Minimum free /dev/shm tmpfs capacity in GiB preserved before evicting completed per-backend virtual environments.                                                 | `32`                  |                          |
| `LIBSCRIPT_TPU_ZONE`                 | GCP compute zone for TPU VM or XPK cluster provisioning.                                                                                                          | `us-central2-b`       | TPU_ZONE                 |
| `LIBSCRIPT_TPU_ACCELERATOR_TYPE`     | Cloud TPU accelerator topology SKU (e.g., v4-8, v5litepod-4, v6e-1).                                                                                              | `v4-8`                | TPU_ACCELERATOR_TYPE     |
| `LIBSCRIPT_TPU_VERSION`              | Cloud TPU runtime OS image version (e.g., tpu-ubuntu2204-base, v2-alpha-tpuv5-lite, v2-alpha-tpuv6e).                                                             | `tpu-ubuntu2204-base` | TPU_VERSION              |
| `LIBSCRIPT_TPU_TENSOR_PARALLEL_SIZE` | Tensor parallelism degree across TPU cores for model serving.                                                                                                     | `1`                   | TPU_TENSOR_PARALLEL_SIZE |
| `LIBSCRIPT_GCP_PROJECT_ID`           | Google Cloud Project ID used for TPU VM or XPK cluster operations.                                                                                                | `none`                | GCP_PROJECT_ID           |
| `LIBSCRIPT_XPK_CLUSTER_NAME`         | Target GKE cluster name managed via XPK.                                                                                                                          | `none`                | XPK_CLUSTER_NAME         |
| `LIBSCRIPT_MODEL_NAME`               | Model repository identifier (e.g., HuggingFace repo ID) served or benchmarked on accelerators.                                                                    | `google/gemma-2-2b`   | MODEL_NAME               |
| `LIBSCRIPT_WORKLOAD_NAME`            | Scheduled XPK or batch training workload identifier.                                                                                                              | `none`                | WORKLOAD_NAME            |
| `TPU_VM_VERSION`                     | Specific version of tpu-vm to install. Can be a numeric version or an alias.                                                                                      | `latest`              | latest, stable           |
| `GCP_TPU_VM_VERSION`                 | Version alias for the gcp-tpu-vm component.                                                                                                                       | `latest`              |                          |
| `TPU_VM_INSTALL_METHOD`              | How to install TPU-VM ('libscript_native' or 'system').                                                                                                           | `libscript_native`    |                          |
| `GCP_TPU_VM_INSTALL_METHOD`          | Installation strategy override for the gcp-tpu-vm component.                                                                                                      | `libscript_native`    |                          |
| `TPU_SCHEDULING_TYPE`                | Scheduling type for the TPU VM (on-demand, spot, or preemptible).                                                                                                 | `on-demand`           |                          |
| `TPU_ACCELERATOR_TYPE`               | Type of TPU accelerator (e.g., v4-8, v4-32, v5litepod-8, v6e-8). Defines the hardware topology.                                                                   | `none`                |                          |
| `TPU_ZONE`                           | GCP Zone for TPU provisioning. Must match an approved grant zone in tfrc.policy.json when TFRC is active.                                                         | `none`                |                          |
| `TPU_VERSION`                        | TPU VM OS runtime version ('auto' resolves v2/v3/v4 -> tpu-ubuntu2204-base, v5litepod/v5e -> v2-alpha-tpuv5-lite, v5p -> v2-alpha-tpuv5, v6e -> v2-alpha-tpuv6e). | `auto`                |                          |
| `TPU_COUNT`                          | Number of independent TPU VMs or pod slices to provision.                                                                                                         | `1`                   |                          |
| `TPU_USE_QUEUED_RESOURCE`            | Whether to use the GCP Queued Resources API for provisioning single-host and multi-host slices.                                                                   | `none`                |                          |
| `TPU_NO_QUEUED_RESOURCE`             | Flag (0 or 1) opting out of Queued Resources when direct tpu-vm creation is explicitly permitted.                                                                 | `0`                   |                          |
| `TPU_DATA_DISK_SIZE`                 | Size of the persistent data disk in GB (optional; stripped to empty in TFRC zero-cost mode).                                                                      | `none`                |                          |
| `TPU_DATA_DISK_TYPE`                 | Type of the persistent data disk (e.g., pd-balanced).                                                                                                             | `pd-balanced`         |                          |
| `TPU_NETWORK`                        | Optional VPC network name for TPU VM provisioning.                                                                                                                | `none`                |                          |
| `TPU_SUBNETWORK`                     | Optional VPC subnetwork name for TPU VM provisioning.                                                                                                             | `none`                |                          |
| `TPU_PROFILE_LOGDIR`                 | Remote directory on TPU VM workers where capture_tpu_profile writes profile traces.                                                                               | `/tmp/tpu_profile`    |                          |
| `TPU_WAIT_TIMEOUT_SEC`               | Maximum timeout in seconds for wait-ready polling of Queued Resources and multi-worker SSH.                                                                       | `1800`                |                          |
| `TPU_WAIT_POLL_SEC`                  | Polling interval in seconds for wait-ready status checks.                                                                                                         | `15`                  |                          |
| `GCP_TPU_VM_ENABLED`                 | Flag (0 or 1) indicating whether gcp-tpu-vm is enabled in the execution plan.                                                                                     | `none`                |                          |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
