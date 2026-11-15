# cli Component

## Overview

This component manages the installation and execution of `cli` within the libscript ecosystem.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CLI_VERSION`              | Specific version of cli to install. Can be a numeric version or an alias.                                                                          | `latest`           | latest, stable   |
| `CLI_INSTALL_METHOD`       | How to install CLI. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise' or 'asdf' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                           | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                        | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                    | `none`             |                  |
| `CLI_LISTEN_PORT`          | Port for CLI to listen on                                                                                                                          | `none`             |                  |
| `CLI_LISTEN_ADDRESS`       | Address for CLI to listen on                                                                                                                       | `none`             |                  |
| `CLI_LISTEN_SOCKET`        | Unix socket for CLI to listen on                                                                                                                   | `none`             |                  |
| `GCP_CLI_ENABLED`          | Flag (0 or 1) indicating whether gcp-cli is enabled in the execution plan.                                                                         | `none`             |                  |
| `GCP_CLI_INSTALL_METHOD`   | Installation method for gcp-cli (libscript_native, system, or from-source).                                                                        | `none`             |                  |
| `GCP_CLI_VERSION`          | Specific version of gcp-cli to install (e.g., latest, lts, or exact version).                                                                      | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
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
