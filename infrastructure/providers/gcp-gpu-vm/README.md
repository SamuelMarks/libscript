# Tier 4 (`T4`) Cloud Provider: Google Cloud GPU Virtual Machines (`infrastructure/providers/gcp-gpu-vm/`)

## Overview

Provisions CUDA-accelerated Google Compute Engine GPU VMs (`T4`, `L4`, `A100`, `H100`) with
automated NVIDIA driver installation, `gcsfuse` dataset mounts, and TensorBoard telemetry.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure gcp-gpu-vm --help

# Provision a node and deploy a stack
./libscript.sh provision gcp-gpu-vm my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure gcp-gpu-vm --help
.\libscript.cmd provision gcp-gpu-vm my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                                                                  | Default            |
| :------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                                                                            | `-`                |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                                                                     | `-`                |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                                                                   | `-`                |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters.                                                  | `-`                |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                                                                               | `-`                |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                                                                               | `-`                |
| `GPU_VM_VERSION`                       | Specific version of gpu-vm to install. Can be a numeric version or an alias.                                                                                 | `latest`           |
| `GPU_VM_INSTALL_METHOD`                | Installation strategy for gcp-gpu-vm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |
| `LIBSCRIPT_LISTEN_PORT`                | Global port to listen on                                                                                                                                     | `-`                |
| `LIBSCRIPT_LISTEN_ADDRESS`             | Global address to listen on                                                                                                                                  | `-`                |
| `LIBSCRIPT_LISTEN_SOCKET`              | Global unix socket to listen on                                                                                                                              | `-`                |
| `GPU_VM_LISTEN_PORT`                   | Port for GPU_VM to listen on                                                                                                                                 | `-`                |
| `GPU_VM_LISTEN_ADDRESS`                | Address for GPU_VM to listen on                                                                                                                              | `-`                |
| `GPU_VM_LISTEN_SOCKET`                 | Unix socket for GPU_VM to listen on                                                                                                                          | `-`                |
| `GCP_GPU_VM_ENABLED`                   | Flag (0 or 1) indicating whether gcp-gpu-vm is enabled in the execution plan.                                                                                | `-`                |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
