# JuiceFS (`_lib/storage-layers/juicefs/`)

## Overview

High-performance cloud-native POSIX distributed filesystem built on top of object storage and
metadata engines.

- **Tier**: `T1` (`_lib/storage-layers/juicefs/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `juicefs`, `distributed-filesystem`

## Usage

```sh
# Install and manage the juicefs service daemon
./libscript.sh install juicefs latest
./libscript.sh start juicefs
./libscript.sh status juicefs
./libscript.sh logs juicefs
./libscript.sh stop juicefs
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install juicefs latest
.\libscript.cmd start juicefs
.\libscript.cmd status juicefs
.\libscript.cmd stop juicefs
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/juicefs/<version>`
  (default `~/.libscript/juicefs/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `JUICEFS_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `JUICEFS_INSTALL_METHOD` | How to install juicefs. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `JUICEFS_VERSION`        | Specific version of juicefs to install.                                                                                                          | `latest`           | latest, lts      |
| `JUICEFS_DOWNLOAD_URL`   | Override URL for downloading juicefs binary or archive artifacts.                                                                                | `none`             |                  |
| `JUICEFS_RELEASES_URL`   | Override URL for querying juicefs available remote releases.                                                                                     | `none`             |                  |
| `JUICEFS_LISTEN_PORT`    | TCP port on which the juicefs service listens.                                                                                                   | `9567`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
