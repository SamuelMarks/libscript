# GKE XPK Training

Deploys a generic ML training job to a Google Cloud TPU or GPU Pod via XPK.

## Components

- cloud-providers/gcp/cli
- toolchains/python
- orchestration/kubernetes/kubectl
- toolchains/xpk

## Variables

- `XPK_CLUSTER_NAME`: Default is 'ml-xpk-cluster'
- `WORKLOAD_NAME`: Default is 'ml-training-job'
- `TPU_ACCELERATOR_TYPE`: Default is 'v4-8'
- `DOCKER_IMAGE`: The training image to use.
