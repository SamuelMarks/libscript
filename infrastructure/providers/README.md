# Tier 4 (`T4`) Cloud & Hypervisor IaaS Providers (`infrastructure/providers/`)

## Overview

`infrastructure/providers/` contains provider-specific IaaS drivers for public clouds, bare-metal
cloud hosts, hardware AI accelerators (Cloud TPUs and GPUs), and on-premise hypervisors. Each
provider implements uniform `cli.{sh,cmd}`, `setup.{sh,cmd}`, `status.{sh,cmd}`, and
`vars.schema.json` contracts dispatched via `./libscript.sh infrastructure <provider>` or
`./libscript.sh provision <provider>`.

## Supported Providers

- [`aws/`](./aws/README.md): Amazon Web Services (EC2, VPC, Security Groups, EBS, S3, AMI import).
- [`azure/`](./azure/README.md): Microsoft Azure (Virtual Machines, VNet, NSG, Managed Disks, VHD).
- [`gcp/`](./gcp/README.md): Google Cloud Platform (Compute Engine, VPC, Firewall, Persistent Disk).
- [`gcp-filestore/`](./gcp-filestore/README.md): Google Cloud Filestore managed NFS tiers for shared
  multi-worker ML and HA workloads.
- [`gcp-gpu-vm/`](./gcp-gpu-vm/README.md): CUDA-enabled GCP GPU Virtual Machines (`T4`, `L4`,
  `A100`, `H100`) with automated driver, `gcsfuse`, and TensorBoard provisioning.
- [`gcp-tpu-vm/`](./gcp-tpu-vm/README.md): Google Cloud TPU VMs and Queued Resources (`v2`, `v3`,
  `v4`, `v5e`, `v5p`, `v6e`) guarded by `engine/common/tfrc_guard.{sh,cmd}`.
- [`digitalocean/`](./digitalocean/README.md): DigitalOcean Droplets, VPCs, Firewalls, and Volumes.
- [`hetzner/`](./hetzner/README.md): Hetzner Cloud servers, private networks, and volumes
  (`hcloud`).
- [`linode/`](./linode/README.md): Akamai Connected Cloud / Linode instances and block storage.
- [`oci/`](./oci/README.md): Oracle Cloud Infrastructure compute instances and VCN networking.
- [`ovh/`](./ovh/README.md): OVHcloud Public Cloud instances and OpenStack/API automation.
- [`proxmox/`](./proxmox/README.md): Proxmox VE KVM virtual machines and LXC templates
  (`qm`/`pvesh`).
- [`vultr/`](./vultr/README.md): Vultr Cloud Compute and bare-metal instances.
