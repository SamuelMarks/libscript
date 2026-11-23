# Rancher K3s Lightweight Kubernetes (`_lib/schedulers/k3s/`)

## Overview

CNCF certified lightweight single-binary Kubernetes distribution (k3s) built for edge, IoT, CI, and
cloud workloads.

- **Tier**: `T1` (`_lib/schedulers/k3s/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `k3s`, `kubernetes-distro`
- **Target OS Whitelist (`manifest.json`)**: `linux`

## Usage

```sh
# Install and manage the k3s service daemon
./libscript.sh install k3s latest
./libscript.sh start k3s
./libscript.sh status k3s
./libscript.sh logs k3s
./libscript.sh stop k3s
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install k3s latest
.\libscript.cmd start k3s
.\libscript.cmd status k3s
.\libscript.cmd stop k3s
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/k3s/<version>`
  (default `~/.libscript/k3s/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `K3S_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `K3S_INSTALL_METHOD` | How to install k3s. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `K3S_VERSION`        | Specific version of k3s to install.                                                                                                          | `latest`           | latest, stable   |
| `K3S_DOWNLOAD_URL`   | Override URL for downloading k3s binary or archive artifacts.                                                                                | `none`             |                  |
| `K3S_RELEASES_URL`   | Override URL for querying k3s available remote releases.                                                                                     | `none`             |                  |
| `K3S_LISTEN_PORT`    | TCP port on which the k3s service listens.                                                                                                   | `6443`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
