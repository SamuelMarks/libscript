# Tier 4 (`T4`) Cloud Provider: OVHcloud (`infrastructure/providers/ovh/`)

## Overview

Provisions and manages OVHcloud Public Cloud compute instances, private networks, and OpenStack/OVH
API resources.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure ovh --help

# Provision a node and deploy a stack
./libscript.sh provision ovh my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure ovh --help
.\libscript.cmd provision ovh my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                       | Default            |
| :------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------ | :----------------- |
| `OVH_INSTALL_METHOD` | How to install ovhcloud. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |
| `OVH_VERSION`        | Specific version of ovhcloud to install.                                                                                                          | `latest`           |
| `OVH_DOWNLOAD_URL`   | Override URL for downloading ovhcloud binary or archive artifacts.                                                                                | `-`                |
| `OVH_RELEASES_URL`   | Override URL for querying ovhcloud available remote releases.                                                                                     | `-`                |
| `OVH_REGION`         | Default OVHcloud Public Cloud region (e.g., GRA11, BHS5, SBG5).                                                                                   | `GRA11`            |
| `OVH_PROJECT_ID`     | Default OVHcloud Public Cloud project serviceName / ID.                                                                                           | `-`                |
| `OVH_FLAVOR`         | Default OVHcloud Public Cloud compute flavor.                                                                                                     | `d2-4`             |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
