# Kubernetes CLI (kubectl) (`_lib/schedulers/kubectl/`)

## Overview

Command-line client (kubectl) for communicating with a Kubernetes cluster control plane.

- **Tier**: `T1` (`_lib/schedulers/kubectl/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `kubectl`, `kubernetes`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/kubectl/<version>)
./libscript.sh ls-remote kubectl
./libscript.sh install kubectl latest
./libscript.sh use kubectl latest
./libscript.sh which kubectl
./_lib/schedulers/kubectl/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote kubectl
.\libscript.cmd install kubectl latest
.\libscript.cmd use kubectl latest
.\libscript.cmd which kubectl
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/kubectl/<version>`
  (default `~/.libscript/kubectl/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `KUBECTL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                               | Default            | Aliases/Examples |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KUBECTL_VERSION`          | Specific version of kubectl to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `KUBECTL_INSTALL_METHOD`   | Installation strategy for kubectl: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                  | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                           | `none`             |                  |
| `KUBECTL_LISTEN_PORT`      | Port for KUBECTL to listen on                                                                                                                             | `none`             |                  |
| `KUBECTL_LISTEN_ADDRESS`   | Address for KUBECTL to listen on                                                                                                                          | `none`             |                  |
| `KUBECTL_LISTEN_SOCKET`    | Unix socket for KUBECTL to listen on                                                                                                                      | `none`             |                  |
| `KUBECTL_DOWNLOAD_URL`     | Override URL for downloading kubectl binary or archive artifacts.                                                                                         | `none`             |                  |
| `KUBECTL_ENABLED`          | Flag (0 or 1) indicating whether kubectl is enabled in the execution plan.                                                                                | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
