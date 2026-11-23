# Tier 4 (`T4`) Multicloud Resource Operators (`infrastructure/resources/`)

## Overview

`infrastructure/resources/` provides provider-agnostic resource lifecycle operators across AWS,
Azure, GCP, and compatible clouds, invoked via `./libscript.sh infrastructure <resource> [args...]`.

## Resource Modules

- [`core/`](./core/README.md): Unified multicloud resource control plane (`node`, `node-group`,
  `network`, `firewall`, `list-managed`, `diff`, `backup`, `cleanup`, `deprovision`) backed by
  `libscript_state.schema.json`.
- [`image-import/`](./image-import/README.md): Uploads and registers `T3` raw/VHD/qcow2/UEFI-GPT OS
  and unikernel images as AWS AMIs, Azure Managed Images, and GCP Custom Images
  (`./libscript.sh import-image`).
- [`storage/`](./storage/README.md): Object storage bucket provisioning, lifecycle rules, and
  CORS/IAM configuration across S3, GCS, and Azure Blob Storage.
- [`volume/`](./volume/README.md): Block storage volume creation, attachment, resizing, and
  snapshots.
- [`cdn/`](./cdn/README.md): Edge CDN distribution provisioning and cache invalidation.
- [`cert/`](./cert/README.md): Cloud-managed TLS/SSL certificate issuance and renewal.
- [`cloudinit/`](./cloudinit/README.md): `cloud-init` user-data rendering and NoCloud seed ISO
  generation (`gen_nocloud_iso.{sh,cmd}`).
