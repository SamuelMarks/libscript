# GKE XPK Multi-Slice Training Payload (`gke-xpk-training`)

Tier 4 payload for provisioning and submitting multi-slice distributed machine learning training
workloads (`JAX`, `MaxText`, `PyTorch/XLA FSDP`, `Keras`) onto Google Kubernetes Engine (GKE) TPU
clusters via `xpk`.

## Usage

```sh
./workloads/payloads/ai/gke-xpk-training/setup.sh
./workloads/payloads/ai/gke-xpk-training/deploy.sh
  --docker-image "gcr.io/my-project/maxtext:latest"
  --command "python3 MaxText/train.py MaxText/configs/base.yml"
  --tpu-type "v5litepod-16"
  --num-slices 2
  --spot
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                             | Description                                                                                                                             | Default               | Aliases/Examples         |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ------------------------ |
| `LIBSCRIPT_TFRC_CONFIG`              | Explicit filesystem path to the user-supplied TFRC zero-cost policy JSON file validated against engine/schemas/tfrc-policy.schema.json. | `none`                |                          |
| `LIBSCRIPT_TFRC_STRICT`              | Flag (0 or 1) enforcing zero-cost TFRC guardrails (blocking GKE, Persistent Disks, static IPs, and non-matching GCS regions).           | `0`                   |                          |
| `LIBSCRIPT_TFRC_STORAGE_MODE`        | Artifact and code transfer transport mode under TFRC enforcement (ssh default, or verified same_region_gcs).                            | `ssh`                 |                          |
| `LIBSCRIPT_TFRC_MAX_TTL_MINUTES`     | Maximum time-to-live in minutes armed on provisioned TPU VM workers via the dead-man's switch timer.                                    | `180`                 |                          |
| `LIBSCRIPT_TFRC_SHM_MIN_FREE_GB`     | Minimum free /dev/shm tmpfs capacity in GiB preserved before evicting completed per-backend virtual environments.                       | `32`                  |                          |
| `LIBSCRIPT_TPU_ZONE`                 | GCP compute zone for TPU VM or XPK cluster provisioning.                                                                                | `us-central2-b`       | TPU_ZONE                 |
| `LIBSCRIPT_TPU_ACCELERATOR_TYPE`     | Cloud TPU accelerator topology SKU (e.g., v4-8, v5litepod-4, v6e-1).                                                                    | `v4-8`                | TPU_ACCELERATOR_TYPE     |
| `LIBSCRIPT_TPU_VERSION`              | Cloud TPU runtime OS image version (e.g., tpu-ubuntu2204-base, v2-alpha-tpuv5-lite, v2-alpha-tpuv6e).                                   | `tpu-ubuntu2204-base` | TPU_VERSION              |
| `LIBSCRIPT_TPU_TENSOR_PARALLEL_SIZE` | Tensor parallelism degree across TPU cores for model serving.                                                                           | `1`                   | TPU_TENSOR_PARALLEL_SIZE |
| `LIBSCRIPT_GCP_PROJECT_ID`           | Google Cloud Project ID used for TPU VM or XPK cluster operations.                                                                      | `none`                | GCP_PROJECT_ID           |
| `LIBSCRIPT_XPK_CLUSTER_NAME`         | Target GKE cluster name managed via XPK.                                                                                                | `none`                | XPK_CLUSTER_NAME         |
| `LIBSCRIPT_MODEL_NAME`               | Model repository identifier (e.g., HuggingFace repo ID) served or benchmarked on accelerators.                                          | `google/gemma-2-2b`   | MODEL_NAME               |
| `LIBSCRIPT_WORKLOAD_NAME`            | Scheduled XPK or batch training workload identifier.                                                                                    | `none`                | WORKLOAD_NAME            |
| `XPK_CLUSTER_NAME`                   | Name of the target GKE XPK cluster.                                                                                                     | `ml-xpk-cluster`      |                          |
| `WORKLOAD_NAME`                      | Unique identifier for the XPK training workload.                                                                                        | `ml-training-job`     |                          |
| `TRAIN_SCRIPT`                       | Training entrypoint command executed inside the container across TPU slices.                                                            | `python train.py`     |                          |
| `DOCKER_IMAGE`                       | Container image containing the JAX/MaxText/PyTorch training environment.                                                                | `none`                |                          |
| `TPU_ACCELERATOR_TYPE`               | TPU accelerator topology (e.g. v4-8, v5litepod-16, v5p-8).                                                                              | `v4-8`                |                          |
| `TPU_SLICE_COUNT`                    | Number of TPU slices for multi-slice data-parallel / FSDP training.                                                                     | `1`                   |                          |
| `TPU_SCHEDULING_TYPE`                | Provisioning scheduling mode ('spot' for TFRC/preemptible or 'on-demand').                                                              | `none`                |                          |
| `GCP_PROJECT_ID`                     | Google Cloud Project ID hosting the GKE XPK cluster.                                                                                    | `none`                |                          |
| `GCP_ZONE`                           | Google Cloud compute zone where the TPU nodes reside.                                                                                   | `none`                |                          |
| `HF_TOKEN`                           | Optional Hugging Face authentication token injected into the workload.                                                                  | `none`                |                          |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
