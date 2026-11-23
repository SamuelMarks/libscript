# Tier 4 (`T4`) Cloud Provider: Vultr Cloud Compute (`infrastructure/providers/vultr/`)

## Overview

Provisions and manages Vultr Cloud Compute and bare-metal instances, VPCs, and block storage.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure vultr --help

# Provision a node and deploy a stack
./libscript.sh provision vultr my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure vultr --help
.\libscript.cmd provision vultr my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            |
| :--------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------ | :----------------- |
| `VULTR_VERSION`        | Specific version of vultr CLI (vultr-cli) to install.                                                                                                   | `latest`           |
| `VULTR_INSTALL_METHOD` | Installation strategy for vultr: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |
| `VULTR_REGION`         | Vultr region code (e.g., ewr, ord, ams) where cloud compute instances are provisioned.                                                                  | `-`                |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
