# Kubernetes k0s (`_lib/schedulers/kubernetes-k0s/`)

## Overview

A zero-friction, all-in-one Kubernetes distribution.

- **Tier**: `T1` (`_lib/schedulers/kubernetes-k0s/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `kubernetes`, `k0s`, `orchestration`, `server`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `sunos`, `freebsd`, `bsd`, `darwin`

## Usage

```sh
# Install and manage the kubernetes-k0s service daemon
./libscript.sh install kubernetes-k0s latest
./libscript.sh start kubernetes-k0s
./libscript.sh status kubernetes-k0s
./libscript.sh logs kubernetes-k0s
./libscript.sh stop kubernetes-k0s
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install kubernetes-k0s latest
.\libscript.cmd start kubernetes-k0s
.\libscript.cmd status kubernetes-k0s
.\libscript.cmd stop kubernetes-k0s
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/kubernetes-k0s/<version>` (default `~/.libscript/kubernetes-k0s/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `KUBERNETES_K0S_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KUBERNETES_K0S_VERSION`        | Specific version of k0s to install                                                                                                                               | `latest`           |                  |
| `KUBERNETES_K0S_DEST`           | Destination (working directory)                                                                                                                                  | `none`             |                  |
| `KUBERNETES_K0S_VARS`           | Key/value in JSON format (as an escaped string)                                                                                                                  | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                         | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                      | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                  | `none`             |                  |
| `KUBERNETES_K0S_LISTEN_PORT`    | Port for KUBERNETES_K0S to listen on                                                                                                                             | `none`             |                  |
| `KUBERNETES_K0S_LISTEN_ADDRESS` | Address for KUBERNETES_K0S to listen on                                                                                                                          | `none`             |                  |
| `KUBERNETES_K0S_LISTEN_SOCKET`  | Unix socket for KUBERNETES_K0S to listen on                                                                                                                      | `none`             |                  |
| `KUBERNETES_K0S_INSTALL_METHOD` | Installation strategy for kubernetes-k0s: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `KUBERNETES_K0S_DOWNLOAD_URL`   | Override URL for downloading kubernetes-k0s binary or archive artifacts.                                                                                         | `none`             |                  |
| `KUBERNETES_K0S_RELEASES_URL`   | Override URL for querying kubernetes-k0s available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
