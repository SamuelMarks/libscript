# Ceph (`_lib/storage-layers/ceph/`)

## Overview

Unified distributed storage cluster providing RADOS object, RBD block, and CephFS file storage.

- **Tier**: `T1` (`_lib/storage-layers/ceph/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `ceph`, `distributed-storage`, `object-storage`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `darwin`

## Usage

```sh
# Install and manage the ceph service daemon
./libscript.sh install ceph latest
./libscript.sh start ceph
./libscript.sh status ceph
./libscript.sh logs ceph
./libscript.sh stop ceph
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install ceph latest
.\libscript.cmd start ceph
.\libscript.cmd status ceph
.\libscript.cmd stop ceph
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ceph/<version>`
  (default `~/.libscript/ceph/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CEPH_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `backup_tenant.{sh,cmd}`,
`configure.{sh,cmd}`, `deprovision_tenant.{sh,cmd}`, `log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`,
`metrics.{sh,cmd}`, `probe.{sh,cmd}`, `provision_tenant.{sh,cmd}`, `restore.{sh,cmd}`,
`restore_tenant.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `CEPH_INSTALL_METHOD` | How to install ceph. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `CEPH_VERSION`        | Specific version of ceph to install.                                                                                                          | `latest` | latest, lts      |
| `CEPH_DOWNLOAD_URL`   | Override URL for downloading ceph binary or archive artifacts.                                                                                | `none`   |                  |
| `CEPH_RELEASES_URL`   | Override URL for querying ceph available remote releases.                                                                                     | `none`   |                  |
| `CEPH_LISTEN_PORT`    | TCP port on which the ceph service listens.                                                                                                   | `6789`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
