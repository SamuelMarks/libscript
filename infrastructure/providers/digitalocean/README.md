# Tier 4 (`T4`) Cloud Provider: DigitalOcean (`infrastructure/providers/digitalocean/`)

## Overview

Provisions and manages DigitalOcean Droplets, VPC networks, Cloud Firewalls, and Block Storage
volumes via `doctl` / REST APIs.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure digitalocean --help

# Provision a node and deploy a stack
./libscript.sh provision digitalocean my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure digitalocean --help
.\libscript.cmd provision digitalocean my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                                                    | Default            |
| :---------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------- |
| `DIGITALOCEAN_VERSION`        | Specific version of digitalocean CLI (doctl) to install.                                                                                                       | `latest`           |
| `DIGITALOCEAN_INSTALL_METHOD` | Installation strategy for digitalocean: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |
| `DIGITALOCEAN_REGION`         | DigitalOcean datacenter region slug (e.g., nyc3, sfo3, fra1) where Droplets and volumes are provisioned.                                                       | `-`                |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
