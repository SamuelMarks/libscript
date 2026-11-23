# Garage (`_lib/storage-layers/garage/`)

## Overview

Lightweight geo-distributed S3-compatible object storage service designed for self-hosting.

- **Tier**: `T1` (`_lib/storage-layers/garage/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `garage`, `s3-storage`, `object-storage`

## Usage

```sh
# Install and manage the garage service daemon
./libscript.sh install garage latest
./libscript.sh start garage
./libscript.sh status garage
./libscript.sh logs garage
./libscript.sh stop garage
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install garage latest
.\libscript.cmd start garage
.\libscript.cmd status garage
.\libscript.cmd stop garage
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/garage/<version>`
  (default `~/.libscript/garage/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `GARAGE_INSTALL_METHOD` (or global
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

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GARAGE_INSTALL_METHOD` | How to install garage. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GARAGE_VERSION`        | Specific version of garage to install.                                                                                                          | `latest`           | latest, lts      |
| `GARAGE_DOWNLOAD_URL`   | Override URL for downloading garage binary or archive artifacts.                                                                                | `none`             |                  |
| `GARAGE_RELEASES_URL`   | Override URL for querying garage available remote releases.                                                                                     | `none`             |                  |
| `GARAGE_LISTEN_PORT`    | TCP port on which the garage service listens.                                                                                                   | `3900`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
