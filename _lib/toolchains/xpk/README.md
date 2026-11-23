# Google Cloud Accelerated Processing Kit (XPK) (`_lib/toolchains/xpk/`)

## Overview

Google Cloud Accelerated Processing Kit (xpk) for provisioning GKE TPU/GPU clusters and scheduling
distributed AI/ML training and inference workloads.

- **Tier**: `T1` (`_lib/toolchains/xpk/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/xpk/<version>)
./libscript.sh ls-remote xpk
./libscript.sh install xpk latest
./libscript.sh use xpk latest
./libscript.sh which xpk
./_lib/toolchains/xpk/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote xpk
.\libscript.cmd install xpk latest
.\libscript.cmd use xpk latest
.\libscript.cmd which xpk
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/xpk/<version>`
  (default `~/.libscript/xpk/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `XPK_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                             | Description                                                                                                                                           | Default               | Aliases/Examples         |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ------------------------ |
| `LIBSCRIPT_TPU_ZONE`                 | GCP compute zone for TPU VM or XPK cluster provisioning.                                                                                              | `us-central2-b`       | TPU_ZONE                 |
| `LIBSCRIPT_TPU_ACCELERATOR_TYPE`     | Cloud TPU accelerator topology SKU (e.g., v4-8, v5litepod-4, v6e-1).                                                                                  | `v4-8`                | TPU_ACCELERATOR_TYPE     |
| `LIBSCRIPT_TPU_VERSION`              | Cloud TPU runtime OS image version (e.g., tpu-ubuntu2204-base, v2-alpha-tpuv5-lite, v2-alpha-tpuv6e).                                                 | `tpu-ubuntu2204-base` | TPU_VERSION              |
| `LIBSCRIPT_TPU_TENSOR_PARALLEL_SIZE` | Tensor parallelism degree across TPU cores for model serving.                                                                                         | `1`                   | TPU_TENSOR_PARALLEL_SIZE |
| `LIBSCRIPT_GCP_PROJECT_ID`           | Google Cloud Project ID used for TPU VM or XPK cluster operations.                                                                                    | `none`                | GCP_PROJECT_ID           |
| `LIBSCRIPT_XPK_CLUSTER_NAME`         | Target GKE cluster name managed via XPK.                                                                                                              | `none`                | XPK_CLUSTER_NAME         |
| `LIBSCRIPT_MODEL_NAME`               | Model repository identifier (e.g., HuggingFace repo ID) served or benchmarked on accelerators.                                                        | `google/gemma-2-2b`   | MODEL_NAME               |
| `LIBSCRIPT_WORKLOAD_NAME`            | Scheduled XPK or batch training workload identifier.                                                                                                  | `none`                | WORKLOAD_NAME            |
| `XPK_VERSION`                        | Specific version of xpk to install. Can be a numeric version or an alias.                                                                             | `latest`              | latest, stable           |
| `XPK_INSTALL_METHOD`                 | Installation strategy for xpk: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system`              |                          |
| `LIBSCRIPT_LISTEN_PORT`              | Global port to listen on                                                                                                                              | `none`                |                          |
| `LIBSCRIPT_LISTEN_ADDRESS`           | Global address to listen on                                                                                                                           | `none`                |                          |
| `LIBSCRIPT_LISTEN_SOCKET`            | Global unix socket to listen on                                                                                                                       | `none`                |                          |
| `XPK_LISTEN_PORT`                    | Port for XPK to listen on                                                                                                                             | `none`                |                          |
| `XPK_LISTEN_ADDRESS`                 | Address for XPK to listen on                                                                                                                          | `none`                |                          |
| `XPK_LISTEN_SOCKET`                  | Unix socket for XPK to listen on                                                                                                                      | `none`                |                          |
| `XPK_DOWNLOAD_URL`                   | Override URL for downloading xpk binary or archive artifacts.                                                                                         | `none`                |                          |
| `XPK_RELEASES_URL`                   | Override URL for querying xpk available remote releases.                                                                                              | `none`                |                          |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
