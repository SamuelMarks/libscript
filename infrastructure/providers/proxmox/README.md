# Tier 4 (`T4`) Cloud Provider: Proxmox Virtual Environment (PVE) (`infrastructure/providers/proxmox/`)

## Overview

Provisions and manages on-premise Proxmox VE KVM virtual machines, cloud-init templates, and LXC
containers via `qm`, `pct`, and `pvesh`.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure proxmox --help

# Provision a node and deploy a stack
./libscript.sh provision proxmox my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure proxmox --help
.\libscript.cmd provision proxmox my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                              | Default  |
| :----------------------- | :------------------------------------------------------------------------------------------------------- | :------- |
| `PROXMOX_VERSION`        | Specific version of proxmox to install.                                                                  | `latest` |
| `PROXMOX_INSTALL_METHOD` | How to install PROXMOX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
