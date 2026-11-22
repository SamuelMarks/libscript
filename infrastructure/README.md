# Tier 4 (`T4`): Infrastructure Providers & Cluster Substrates (`infrastructure/`)

## Overview

`infrastructure/` provisions cloud and bare-metal compute/network/storage fleets, imports `T3`
machine images, publishes cloud Marketplace offers, and bootstraps target cluster substrates:

- `infrastructure/providers/`: Cloud and hypervisor IaaS operators (`aws`, `azure`, `gcp`,
  `gcp-tpu-vm`, `gcp-gpu-vm`, `gcp-filestore`, `digitalocean`, `hetzner`, `linode`, `oci`, `ovh`,
  `proxmox`, `vultr`).
- `infrastructure/resources/`: Cloud-agnostic object storage, CDN, TLS certificate, block volume,
  `NoCloud` `cloud-init`, and custom image import operators.
- `infrastructure/clusters/`: Cluster-forming substrate topologies (`k0s-ha`, `gke-tpu-cluster`,
  `k8s-marathon-paas`, `mesos-marathon-ha`, `kubernetes-thw`) governed by
  `cluster-substrate.schema.json` and backed by `T0` `engine/consensus/`.
- `infrastructure/marketplace/`: AWS, Azure, and GCP Marketplace offer publishing and compliance
  verification.
