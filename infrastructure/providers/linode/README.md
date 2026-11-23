# Tier 4 (`T4`) Cloud Provider: Linode (Akamai Connected Cloud) (`infrastructure/providers/linode/`)

## Overview

Provisions and manages Akamai / Linode cloud instances, VLANs, firewalls, and block storage volumes.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure linode --help

# Provision a node and deploy a stack
./libscript.sh provision linode my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure linode --help
.\libscript.cmd provision linode my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------- |
| `LINODE_VERSION`        | Specific version of linode CLI (linode-cli) to install.                                                                                                  | `latest`           |
| `LINODE_INSTALL_METHOD` | Installation strategy for linode: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |
| `LINODE_REGION`         | Akamai/Linode region identifier (e.g., us-east, eu-central) where compute instances are deployed.                                                        | `-`                |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
