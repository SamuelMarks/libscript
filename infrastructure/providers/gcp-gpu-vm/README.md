# gpu-vm Component

## Overview

This component manages the installation and execution of `gpu-vm` within the libscript ecosystem.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                                                                     | `none`             |                  |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                                                              | `none`             |                  |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                                                            | `none`             |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters.                                           | `none`             |                  |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                                                                        | `none`             |                  |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                                                                        | `none`             |                  |
| `GPU_VM_VERSION`                       | Specific version of gpu-vm to install. Can be a numeric version or an alias.                                                                          | `latest`           | latest, stable   |
| `GPU_VM_INSTALL_METHOD`                | How to install GPU-VM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise' or 'asdf' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`                | Global port to listen on                                                                                                                              | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`             | Global address to listen on                                                                                                                           | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`              | Global unix socket to listen on                                                                                                                       | `none`             |                  |
| `GPU_VM_LISTEN_PORT`                   | Port for GPU_VM to listen on                                                                                                                          | `none`             |                  |
| `GPU_VM_LISTEN_ADDRESS`                | Address for GPU_VM to listen on                                                                                                                       | `none`             |                  |
| `GPU_VM_LISTEN_SOCKET`                 | Unix socket for GPU_VM to listen on                                                                                                                   | `none`             |                  |
| `GCP_GPU_VM_ENABLED`                   | Flag (0 or 1) indicating whether gcp-gpu-vm is enabled in the execution plan.                                                                         | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Install Method

By default, `libscript` will install this component natively using the `libscript_native` method.
You can override this behavior by setting `<COMPONENT>_INSTALL_METHOD` to `system`, `mise`, `asdf`,
etc.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
