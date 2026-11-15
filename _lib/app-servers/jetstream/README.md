# jetstream Component

## Overview

This component manages the installation and execution of `jetstream` within the libscript ecosystem.
Libscript manages Jetstream versions natively by installing them into isolated virtual environments
under `LIBSCRIPT_HOME/jetstream/<version>`.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

_Note: The default install method is `libscript_native`._

## Configuration

| Variable                   | Description                                                                                                                                                               | Default            | Required |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `JETSTREAM_INSTALL_METHOD` | How to install JETSTREAM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                             | Description                                                                                                                                                               | Default                                                                     | Aliases/Examples         |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ------------------------ |
| `LIBSCRIPT_TPU_ZONE`                 | GCP compute zone for TPU VM or XPK cluster provisioning.                                                                                                                  | `us-central2-b`                                                             | TPU_ZONE                 |
| `LIBSCRIPT_TPU_ACCELERATOR_TYPE`     | Cloud TPU accelerator topology SKU (e.g., v4-8, v5litepod-4, v6e-1).                                                                                                      | `v4-8`                                                                      | TPU_ACCELERATOR_TYPE     |
| `LIBSCRIPT_TPU_VERSION`              | Cloud TPU runtime OS image version (e.g., tpu-ubuntu2204-base, v2-alpha-tpuv5-lite, v2-alpha-tpuv6e).                                                                     | `tpu-ubuntu2204-base`                                                       | TPU_VERSION              |
| `LIBSCRIPT_TPU_TENSOR_PARALLEL_SIZE` | Tensor parallelism degree across TPU cores for model serving.                                                                                                             | `1`                                                                         | TPU_TENSOR_PARALLEL_SIZE |
| `LIBSCRIPT_GCP_PROJECT_ID`           | Google Cloud Project ID used for TPU VM or XPK cluster operations.                                                                                                        | `none`                                                                      | GCP_PROJECT_ID           |
| `LIBSCRIPT_XPK_CLUSTER_NAME`         | Target GKE cluster name managed via XPK.                                                                                                                                  | `none`                                                                      | XPK_CLUSTER_NAME         |
| `LIBSCRIPT_MODEL_NAME`               | Model repository identifier (e.g., HuggingFace repo ID) served or benchmarked on accelerators.                                                                            | `google/gemma-2-2b`                                                         | MODEL_NAME               |
| `LIBSCRIPT_WORKLOAD_NAME`            | Scheduled XPK or batch training workload identifier.                                                                                                                      | `none`                                                                      | WORKLOAD_NAME            |
| `JETSTREAM_VERSION`                  | Specific version of jetstream to install. Can be a numeric version or an alias.                                                                                           | `latest`                                                                    | latest, stable           |
| `JETSTREAM_INSTALL_METHOD`           | How to install JETSTREAM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`                                                          |                          |
| `JETSTREAM_IMAGE`                    | Container image URI used when serving JetStream TPU inference workloads.                                                                                                  | `us-docker.pkg.dev/cloud-tpu-images/inference/jetstream-pytorch-tpu:latest` |                          |
| `JETSTREAM_REMOTE_TPU_HOST`          | Optional SSH host/alias of a Linux Cloud TPU VM to forward JetStream launch commands to when invoked from non-TPU hosts.                                                  | `none`                                                                      |                          |
| `LIBSCRIPT_LISTEN_PORT`              | Global port to listen on                                                                                                                                                  | `none`                                                                      |                          |
| `LIBSCRIPT_LISTEN_ADDRESS`           | Global address to listen on                                                                                                                                               | `none`                                                                      |                          |
| `LIBSCRIPT_LISTEN_SOCKET`            | Global unix socket to listen on                                                                                                                                           | `none`                                                                      |                          |
| `JETSTREAM_LISTEN_PORT`              | Port for JETSTREAM to listen on                                                                                                                                           | `none`                                                                      |                          |
| `JETSTREAM_LISTEN_ADDRESS`           | Address for JETSTREAM to listen on                                                                                                                                        | `none`                                                                      |                          |
| `JETSTREAM_LISTEN_SOCKET`            | Unix socket for JETSTREAM to listen on                                                                                                                                    | `none`                                                                      |                          |
| `JETSTREAM_DOWNLOAD_URL`             | Override URL for downloading jetstream binary or archive artifacts.                                                                                                       | `none`                                                                      |                          |
| `JETSTREAM_RELEASES_URL`             | Override URL for querying jetstream available remote releases.                                                                                                            | `none`                                                                      |                          |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
