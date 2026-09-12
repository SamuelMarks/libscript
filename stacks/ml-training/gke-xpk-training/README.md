# GKE XPK Training

Deploys a generic ML training job to a Google Cloud TPU or GPU Pod via XPK.

## Components

- cloud-providers/gcp/cli
- toolchains/python
- orchestration/kubernetes/kubectl
- toolchains/xpk

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                      | Default           | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------- | ----------------- | ---------------- |
| `XPK_CLUSTER_NAME`     | Name of the Google Kubernetes Engine XPK cluster                 | `ml-xpk-cluster`  |                  |
| `GCP_PROJECT_ID`       | Google Cloud Project ID where the cluster is created             | ``                |                  |
| `GCP_ZONE`             | Google Cloud Zone for the XPK cluster (e.g. us-central2-b)       | ``                |                  |
| `TPU_ACCELERATOR_TYPE` | TPU accelerator type for the training nodes (e.g. v4-8, v5e-16)  | `v4-8`            |                  |
| `WORKLOAD_NAME`        | Identifier for the training workload job                         | `ml-training-job` |                  |
| `TRAIN_SCRIPT`         | Command or script executed inside the training container         | `python train.py` |                  |
| `DOCKER_IMAGE`         | Docker container image containing training code and dependencies | ``                |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
