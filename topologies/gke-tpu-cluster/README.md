# Tier 3.5 Topology Blueprint: `gke-tpu-cluster`

## Overview

`topologies/gke-tpu-cluster/` defines a multi-pool Google Kubernetes Engine (GKE) + Cloud TPU
multi-slice cluster topology orchestrated via `xpk` and `gcloud`. It separates multi-node GKE + TPU
pool choreography from pure single-resource IaaS providers (`_lib/cloud-providers/`) and ephemeral
AI training/inference workloads (`payloads/ai/`).

## Usage

```sh
./topologies/gke-tpu-cluster/cli.sh create my-tpu-cluster
./topologies/gke-tpu-cluster/cli.sh delete my-tpu-cluster
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
