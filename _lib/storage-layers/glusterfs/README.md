# GlusterFS (`_lib/storage-layers/glusterfs/`)

## Overview

Scalable distributed network filesystem aggregating disk storage resources into a unified namespace.

- **Tier**: `T1` (`_lib/storage-layers/glusterfs/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `glusterfs`, `network-filesystem`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `darwin`

## Usage

```sh
# Install and manage the glusterfs service daemon
./libscript.sh install glusterfs latest
./libscript.sh start glusterfs
./libscript.sh status glusterfs
./libscript.sh logs glusterfs
./libscript.sh stop glusterfs
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install glusterfs latest
.\libscript.cmd start glusterfs
.\libscript.cmd status glusterfs
.\libscript.cmd stop glusterfs
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/glusterfs/<version>`
  (default `~/.libscript/glusterfs/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GLUSTERFS_INSTALL_METHOD` (or global
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

| Variable                   | Description                                                                                                                                        | Default  | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `GLUSTERFS_INSTALL_METHOD` | How to install glusterfs. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `GLUSTERFS_VERSION`        | Specific version of glusterfs to install.                                                                                                          | `latest` | latest, lts      |
| `GLUSTERFS_DOWNLOAD_URL`   | Override URL for downloading glusterfs binary or archive artifacts.                                                                                | `none`   |                  |
| `GLUSTERFS_RELEASES_URL`   | Override URL for querying glusterfs available remote releases.                                                                                     | `none`   |                  |
| `GLUSTERFS_LISTEN_PORT`    | TCP port on which the glusterfs service listens.                                                                                                   | `24007`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
