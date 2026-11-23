# Google Cloud CLI (`_lib/toolchains/gcp-cli/`)

## Overview

Component for installing and managing the Google Cloud CLI (gcloud).

- **Tier**: `T1` (`_lib/toolchains/gcp-cli/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `gcloud`, `gcloud-cli`, `gcp-cli`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/gcp-cli/<version>)
./libscript.sh ls-remote gcp-cli
./libscript.sh install gcp-cli latest
./libscript.sh use gcp-cli latest
./libscript.sh which gcp-cli
./_lib/toolchains/gcp-cli/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote gcp-cli
.\libscript.cmd install gcp-cli latest
.\libscript.cmd use gcp-cli latest
.\libscript.cmd which gcp-cli
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/gcp-cli/<version>`
  (default `~/.libscript/gcp-cli/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GCP_CLI_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                               | Default            | Aliases/Examples |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CLI_VERSION`              | Specific version of cli to install. Can be a numeric version or an alias.                                                                                 | `latest`           | latest, stable   |
| `CLI_INSTALL_METHOD`       | Installation strategy for gcp-cli: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                  | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                           | `none`             |                  |
| `CLI_LISTEN_PORT`          | Port for CLI to listen on                                                                                                                                 | `none`             |                  |
| `CLI_LISTEN_ADDRESS`       | Address for CLI to listen on                                                                                                                              | `none`             |                  |
| `CLI_LISTEN_SOCKET`        | Unix socket for CLI to listen on                                                                                                                          | `none`             |                  |
| `GCP_CLI_ENABLED`          | Flag (0 or 1) indicating whether gcp-cli is enabled in the execution plan.                                                                                | `none`             |                  |
| `GCP_CLI_INSTALL_METHOD`   | Installation method for gcp-cli (libscript_native, system, or from-source).                                                                               | `none`             |                  |
| `GCP_CLI_VERSION`          | Specific version of gcp-cli to install (e.g., latest, lts, or exact version).                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
