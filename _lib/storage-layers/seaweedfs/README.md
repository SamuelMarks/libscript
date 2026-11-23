# SeaweedFS (`_lib/storage-layers/seaweedfs/`)

## Overview

Fast distributed blob storage, Filer POSIX filesystem, and S3-compatible object store with O(1) disk
seek.

- **Tier**: `T1` (`_lib/storage-layers/seaweedfs/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `seaweedfs`, `weed`, `blob-storage`, `s3-storage`

## Usage

```sh
# Install and manage the seaweedfs service daemon
./libscript.sh install seaweedfs latest
./libscript.sh start seaweedfs
./libscript.sh status seaweedfs
./libscript.sh logs seaweedfs
./libscript.sh stop seaweedfs
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install seaweedfs latest
.\libscript.cmd start seaweedfs
.\libscript.cmd status seaweedfs
.\libscript.cmd stop seaweedfs
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/seaweedfs/<version>`
  (default `~/.libscript/seaweedfs/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `SEAWEEDFS_INSTALL_METHOD` (or global
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

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SEAWEEDFS_INSTALL_METHOD` | How to install seaweedfs. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SEAWEEDFS_VERSION`        | Specific version of seaweedfs to install.                                                                                                          | `latest`           | latest, lts      |
| `SEAWEEDFS_DOWNLOAD_URL`   | Override URL for downloading seaweedfs binary or archive artifacts.                                                                                | `none`             |                  |
| `SEAWEEDFS_RELEASES_URL`   | Override URL for querying seaweedfs available remote releases.                                                                                     | `none`             |                  |
| `SEAWEEDFS_LISTEN_PORT`    | TCP port on which the seaweedfs service listens.                                                                                                   | `9333`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
