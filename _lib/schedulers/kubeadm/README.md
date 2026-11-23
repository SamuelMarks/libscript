# Kubernetes kubeadm Bootstrapper (`_lib/schedulers/kubeadm/`)

## Overview

Official Kubernetes cluster lifecycle bootstrapper (kubeadm init, kubeadm join, kubeadm upgrade).

- **Tier**: `T1` (`_lib/schedulers/kubeadm/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/kubeadm/<version>)
./libscript.sh ls-remote kubeadm
./libscript.sh install kubeadm latest
./libscript.sh use kubeadm latest
./libscript.sh which kubeadm
./_lib/schedulers/kubeadm/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote kubeadm
.\libscript.cmd install kubeadm latest
.\libscript.cmd use kubeadm latest
.\libscript.cmd which kubeadm
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/kubeadm/<version>`
  (default `~/.libscript/kubeadm/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `KUBEADM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `KUBEADM_INSTALL_METHOD` | How to install kubeadm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `KUBEADM_VERSION`        | Specific version of kubeadm to install.                                                                                                          | `latest`           | latest, stable   |
| `KUBEADM_DOWNLOAD_URL`   | Override URL for downloading kubeadm binary or archive artifacts.                                                                                | `none`             |                  |
| `KUBEADM_RELEASES_URL`   | Override URL for querying kubeadm available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
