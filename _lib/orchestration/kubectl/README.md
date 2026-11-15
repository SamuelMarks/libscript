# kubectl Component

## Overview

This component manages the installation and execution of `kubectl` within the libscript
ecolibscript_native.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                            | Default            | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `KUBECTL_VERSION`          | Specific version of kubectl to install. Can be a numeric version or an alias.                                                                          | `latest`           | latest, stable   |
| `KUBECTL_INSTALL_METHOD`   | How to install KUBECTL. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise' or 'asdf' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                            | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                        | `none`             |                  |
| `KUBECTL_LISTEN_PORT`      | Port for KUBECTL to listen on                                                                                                                          | `none`             |                  |
| `KUBECTL_LISTEN_ADDRESS`   | Address for KUBECTL to listen on                                                                                                                       | `none`             |                  |
| `KUBECTL_LISTEN_SOCKET`    | Unix socket for KUBECTL to listen on                                                                                                                   | `none`             |                  |
| `KUBECTL_DOWNLOAD_URL`     | Override URL for downloading kubectl binary or archive artifacts.                                                                                      | `none`             |                  |
| `KUBECTL_ENABLED`          | Flag (0 or 1) indicating whether kubectl is enabled in the execution plan.                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
