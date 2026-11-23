# Etcd (`_lib/databases/etcd/`)

## Overview

A distributed, reliable key-value store for the most critical data of a distributed system.

- **Tier**: `T1` (`_lib/databases/etcd/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `kv-store`, `etcd`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the etcd service daemon
./libscript.sh install etcd latest
./libscript.sh start etcd
./libscript.sh status etcd
./libscript.sh logs etcd
./libscript.sh stop etcd
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install etcd latest
.\libscript.cmd start etcd
.\libscript.cmd status etcd
.\libscript.cmd stop etcd
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/etcd/<version>`
  (default `~/.libscript/etcd/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ETCD_INSTALL_METHOD` (or global
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

| Variable                       | Description                                                                                                                                            | Default            | Aliases/Examples |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `ETCD_VERSION`                 | Version of PostgreSQL demanded                                                                                                                         | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`        | Global port to listen on                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`     | Global address to listen on                                                                                                                            | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`      | Global unix socket to listen on                                                                                                                        | `none`             |                  |
| `ETCD_LISTEN_PORT`             | Port for ETCD to listen on                                                                                                                             | `none`             |                  |
| `ETCD_LISTEN_ADDRESS`          | Address for ETCD to listen on                                                                                                                          | `none`             |                  |
| `ETCD_LISTEN_SOCKET`           | Unix socket for ETCD to listen on                                                                                                                      | `none`             |                  |
| `ETCD_DATA_DIR`                | Directory for Etcd data                                                                                                                                | `none`             |                  |
| `ETCD_SERVICE_RUN_AS_USER`     | Windows local user account to run the service (leave empty for Network Service)                                                                        | `none`             |                  |
| `ETCD_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable)                                                                                                    | `none`             |                  |
| `ETCD_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations)                                                                                | `libscript_etcd`   |                  |
| `ETCD_SERVICE_USER`            | User for etcd service.                                                                                                                                 | `none`             |                  |
| `ETCD_URL`                     | URL for etcd.                                                                                                                                          | `none`             |                  |
| `ETCD_SERVICE_GROUP`           | Group for etcd service.                                                                                                                                | `none`             |                  |
| `ETCD_INSTALL_METHOD`          | Installation strategy for etcd: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `ETCD_DOWNLOAD_URL`            | Override URL for downloading etcd binary or archive artifacts.                                                                                         | `none`             |                  |
| `ETCD_PASSWORD_FILE`           | Filesystem path to a file containing the etcd root/authentication password.                                                                            | `none`             |                  |
| `ETCD_RELEASES_URL`            | Override URL for querying etcd available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
