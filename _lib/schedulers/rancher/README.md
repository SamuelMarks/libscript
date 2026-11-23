# Rancher Multi-Cluster Kubernetes Manager (`_lib/schedulers/rancher/`)

## Overview

Rancher multi-cluster Kubernetes management CLI and control-plane server orchestration recipe.

- **Tier**: `T1` (`_lib/schedulers/rancher/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `rancher`, `rancher-cli`

## Usage

```sh
# Install and manage the rancher service daemon
./libscript.sh install rancher latest
./libscript.sh start rancher
./libscript.sh status rancher
./libscript.sh logs rancher
./libscript.sh stop rancher
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install rancher latest
.\libscript.cmd start rancher
.\libscript.cmd status rancher
.\libscript.cmd stop rancher
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/rancher/<version>`
  (default `~/.libscript/rancher/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `RANCHER_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `RANCHER_INSTALL_METHOD` | How to install rancher. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `RANCHER_VERSION`        | Specific version of rancher to install.                                                                                                          | `latest`           | latest, stable   |
| `RANCHER_DOWNLOAD_URL`   | Override URL for downloading rancher binary or archive artifacts.                                                                                | `none`             |                  |
| `RANCHER_RELEASES_URL`   | Override URL for querying rancher available remote releases.                                                                                     | `none`             |                  |
| `RANCHER_LISTEN_PORT`    | TCP port on which the rancher service listens.                                                                                                   | `80`               |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
