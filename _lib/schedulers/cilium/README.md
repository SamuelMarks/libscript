# Cilium CLI (`_lib/schedulers/cilium/`)

## Overview

Cilium CLI (cilium) for installing, managing, and troubleshooting eBPF-powered Kubernetes
networking, observability, and security.

- **Tier**: `T1` (`_lib/schedulers/cilium/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `cilium`, `cilium-cli`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/cilium/<version>)
./libscript.sh ls-remote cilium
./libscript.sh install cilium latest
./libscript.sh use cilium latest
./libscript.sh which cilium
./_lib/schedulers/cilium/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote cilium
.\libscript.cmd install cilium latest
.\libscript.cmd use cilium latest
.\libscript.cmd which cilium
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/cilium/<version>`
  (default `~/.libscript/cilium/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CILIUM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CILIUM_INSTALL_METHOD` | How to install cilium. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CILIUM_VERSION`        | Specific version of cilium to install.                                                                                                          | `latest`           | latest, stable   |
| `CILIUM_DOWNLOAD_URL`   | Override URL for downloading cilium binary or archive artifacts.                                                                                | `none`             |                  |
| `CILIUM_RELEASES_URL`   | Override URL for querying cilium available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
