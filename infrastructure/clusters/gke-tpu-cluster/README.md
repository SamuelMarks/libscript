# T5 Topology Blueprint: `gke-tpu-cluster`

## Overview

`infrastructure/clusters/gke-tpu-cluster/` defines a multi-pool Google Kubernetes Engine (GKE) +
Cloud TPU multi-slice cluster topology orchestrated via `xpk` and `gcloud`. It separates multi-node
GKE + TPU pool choreography from pure single-resource IaaS providers (`infrastructure/providers/`)
and ephemeral AI training/inference workloads (`workloads/payloads/ai/`).

## Usage

```sh
./infrastructure/clusters/gke-tpu-cluster/cli.sh create my-tpu-cluster
./infrastructure/clusters/gke-tpu-cluster/cli.sh delete my-tpu-cluster
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
