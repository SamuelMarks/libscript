# Tier 4 (`T4`) Cloud Provider: Hetzner Cloud (`infrastructure/providers/hetzner/`)

## Overview

Provisions and manages Hetzner Cloud (`hcloud`) compute servers, private networks, firewalls, and
block volumes.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure hetzner --help

# Provision a node and deploy a stack
./libscript.sh provision hetzner my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure hetzner --help
.\libscript.cmd provision hetzner my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                              | Default  |
| :----------------------- | :------------------------------------------------------------------------------------------------------- | :------- |
| `HETZNER_VERSION`        | Specific version of Hetzner tooling to install.                                                          | `latest` |
| `HETZNER_INSTALL_METHOD` | How to install HETZNER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |
| `HETZNER_IP`             | Override target IPv4/IPv6 address for Hetzner node SSH and rsync operations.                             | `""`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
