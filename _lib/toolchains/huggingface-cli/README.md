# huggingface-cli Component

## Overview

This component manages the installation and execution of `huggingface-cli` within the libscript
ecosystem.

## Usage

_Note: libscript manages versions natively for this component._

Refer to the component's setup and cli scripts for specific operations.

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

## Configuration

| Variable                         | Description                                                                                                                                                                     | Default            | Required |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `HUGGINGFACE_CLI_INSTALL_METHOD` | How to install HUGGINGFACE CLI. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                                     | Default            | Aliases/Examples |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `HUGGINGFACE_CLI_VERSION`        | Specific version of huggingface_hub to install. Can be a numeric version or an alias.                                                                                           | `latest`           | latest, stable   |
| `HUGGINGFACE_CLI_INSTALL_METHOD` | How to install HUGGINGFACE_CLI. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`          | Global port to listen on                                                                                                                                                        | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`       | Global address to listen on                                                                                                                                                     | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`        | Global unix socket to listen on                                                                                                                                                 | `none`             |                  |
| `HUGGINGFACE_CLI_LISTEN_PORT`    | Port for HUGGINGFACE_CLI to listen on                                                                                                                                           | `none`             |                  |
| `HUGGINGFACE_CLI_LISTEN_ADDRESS` | Address for HUGGINGFACE_CLI to listen on                                                                                                                                        | `none`             |                  |
| `HUGGINGFACE_CLI_LISTEN_SOCKET`  | Unix socket for HUGGINGFACE_CLI to listen on                                                                                                                                    | `none`             |                  |
| `HUGGINGFACE_CLI_DOWNLOAD_URL`   | Override URL for downloading huggingface-cli binary or archive artifacts.                                                                                                       | `none`             |                  |
| `HUGGINGFACE_CLI_RELEASES_URL`   | Override URL for querying huggingface-cli available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
