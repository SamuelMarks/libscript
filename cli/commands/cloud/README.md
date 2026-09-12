# LibScript Cloud Commands

## Overview

Orchestrates cloud infrastructure and remote deployments across supported cloud providers (AWS, GCP,
Azure).

## Subcommands

- `provision`: Provisions cloud VMs, networks, storage volumes, and security groups.
- `deprovision`: Destroys provisioned cloud resources and cleans up metadata tags.
- `deploy-remote`: Idempotently synchronizes and executes LibScript manifests on remote hosts over
  SSH.
