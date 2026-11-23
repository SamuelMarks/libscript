# Hugging Face Hub CLI (`_lib/toolchains/huggingface-cli/`)

## Overview

Official Hugging Face Hub CLI (`huggingface-cli` / `hf`) for downloading models, datasets, and
managing repositories.

- **Tier**: `T1` (`_lib/toolchains/huggingface-cli/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `huggingface-cli`, `huggingface_hub`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/huggingface-cli/<version>)
./libscript.sh ls-remote huggingface-cli
./libscript.sh install huggingface-cli latest
./libscript.sh use huggingface-cli latest
./libscript.sh which huggingface-cli
./_lib/toolchains/huggingface-cli/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote huggingface-cli
.\libscript.cmd install huggingface-cli latest
.\libscript.cmd use huggingface-cli latest
.\libscript.cmd which huggingface-cli
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/huggingface-cli/<version>` (default `~/.libscript/huggingface-cli/<version>`)
  and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `HUGGINGFACE_CLI_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                       | Default            | Aliases/Examples |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `HUGGINGFACE_CLI_VERSION`        | Specific version of huggingface_hub to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `HUGGINGFACE_CLI_INSTALL_METHOD` | Installation strategy for huggingface-cli: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`          | Global port to listen on                                                                                                                                          | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`       | Global address to listen on                                                                                                                                       | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`        | Global unix socket to listen on                                                                                                                                   | `none`             |                  |
| `HUGGINGFACE_CLI_LISTEN_PORT`    | Port for HUGGINGFACE_CLI to listen on                                                                                                                             | `none`             |                  |
| `HUGGINGFACE_CLI_LISTEN_ADDRESS` | Address for HUGGINGFACE_CLI to listen on                                                                                                                          | `none`             |                  |
| `HUGGINGFACE_CLI_LISTEN_SOCKET`  | Unix socket for HUGGINGFACE_CLI to listen on                                                                                                                      | `none`             |                  |
| `HUGGINGFACE_CLI_DOWNLOAD_URL`   | Override URL for downloading huggingface-cli binary or archive artifacts.                                                                                         | `none`             |                  |
| `HUGGINGFACE_CLI_RELEASES_URL`   | Override URL for querying huggingface-cli available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
