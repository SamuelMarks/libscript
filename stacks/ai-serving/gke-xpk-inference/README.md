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

| Variable               | Description                                                         | Default          | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------- | ---------------- | ---------------- |
| `XPK_CLUSTER_NAME`     | Name of the Google Kubernetes Engine XPK cluster                    | `ml-xpk-cluster` |                  |
| `GCP_PROJECT_ID`       | Google Cloud Project ID where the cluster is created                | ``               |                  |
| `GCP_ZONE`             | Google Cloud Zone for the XPK cluster (e.g. us-central2-b)          | ``               |                  |
| `TPU_ACCELERATOR_TYPE` | TPU accelerator version and topology (e.g. v4-8, v5e-16)            | `v4-8`           |                  |
| `MODEL_NAME`           | Hugging Face or GCS model identifier served by the inference engine | ``               |                  |
| `WORKLOAD_NAME`        | Kubernetes workload identifier for the inference service            | `ml-serve`       |                  |
| `PORT`                 | Inference server port exposed by the service                        | `8000`           |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
