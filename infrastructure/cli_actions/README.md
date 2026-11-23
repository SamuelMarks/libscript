# Tier 4 (`T4`) Multicloud CLI Action Handlers (`infrastructure/cli_actions/`)

## Overview

`infrastructure/cli_actions/` implements the top-level multicloud lifecycle verbs dispatched by
`./libscript.sh <provision|deprovision|backup|restore>` via `infrastructure/cli.{sh,cmd}`.

## Scripts

- **`provision.{sh,cmd}`**: Provisions cloud compute instances, VPC networks, firewall rules, and
  remote application directories across AWS, Azure, GCP, Hetzner, DigitalOcean, Linode, Vultr, OCI,
  OVH, and Proxmox.
- **`deprovision.{sh,cmd}`**: Performs tag-scoped cascade teardown of compute instances, attached
  volumes, NICs, and security groups while honoring `--retain-ip` and `--retain-data` flags.
- **`backup.{sh,cmd}`** (`backup` / `export-remote`): Orchestrates remote node volume snapshots and
  encrypted archive exports to local or S3/GCS/Azure object storage.
- **`restore.{sh,cmd}`** (`restore` / `import-remote`): Restores cloud node snapshots and remote
  state archives onto replacement or existing `T4` instances.
