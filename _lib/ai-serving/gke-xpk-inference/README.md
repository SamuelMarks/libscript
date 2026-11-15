# gke-xpk-inference Component

## Overview

This component manages the installation and execution of `gke-xpk-inference` within the libscript
ecosystem.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                             | Description                                                                                           | Default               | Aliases/Examples         |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------- | --------------------- | ------------------------ |
| `LIBSCRIPT_TPU_ZONE`                 | GCP compute zone for TPU VM or XPK cluster provisioning.                                              | `us-central2-b`       | TPU_ZONE                 |
| `LIBSCRIPT_TPU_ACCELERATOR_TYPE`     | Cloud TPU accelerator topology SKU (e.g., v4-8, v5litepod-4, v6e-1).                                  | `v4-8`                | TPU_ACCELERATOR_TYPE     |
| `LIBSCRIPT_TPU_VERSION`              | Cloud TPU runtime OS image version (e.g., tpu-ubuntu2204-base, v2-alpha-tpuv5-lite, v2-alpha-tpuv6e). | `tpu-ubuntu2204-base` | TPU_VERSION              |
| `LIBSCRIPT_TPU_TENSOR_PARALLEL_SIZE` | Tensor parallelism degree across TPU cores for model serving.                                         | `1`                   | TPU_TENSOR_PARALLEL_SIZE |
| `LIBSCRIPT_GCP_PROJECT_ID`           | Google Cloud Project ID used for TPU VM or XPK cluster operations.                                    | `none`                | GCP_PROJECT_ID           |
| `LIBSCRIPT_XPK_CLUSTER_NAME`         | Target GKE cluster name managed via XPK.                                                              | `none`                | XPK_CLUSTER_NAME         |
| `LIBSCRIPT_MODEL_NAME`               | Model repository identifier (e.g., HuggingFace repo ID) served or benchmarked on accelerators.        | `google/gemma-2-2b`   | MODEL_NAME               |
| `LIBSCRIPT_WORKLOAD_NAME`            | Scheduled XPK or batch training workload identifier.                                                  | `none`                | WORKLOAD_NAME            |
| `XPK_CLUSTER_NAME`                   | Name of the Google Kubernetes Engine XPK cluster                                                      | `ml-xpk-cluster`      |                          |
| `GCP_PROJECT_ID`                     | Google Cloud Project ID where the cluster is created                                                  | ``                    |                          |
| `GCP_ZONE`                           | Google Cloud Zone for the XPK cluster (e.g. us-central2-b)                                            | ``                    |                          |
| `TPU_ACCELERATOR_TYPE`               | TPU accelerator version and topology (e.g. v4-8, v5e-16)                                              | `v4-8`                |                          |
| `MODEL_NAME`                         | Hugging Face or GCS model identifier served by the inference engine                                   | ``                    |                          |
| `WORKLOAD_NAME`                      | Kubernetes workload identifier for the inference service                                              | `ml-serve`            |                          |
| `PORT`                               | Inference server port exposed by the service                                                          | `8000`                |                          |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
