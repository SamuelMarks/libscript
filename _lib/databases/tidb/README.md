# TiDB (`_lib/databases/tidb/`)

## Overview

Open-source distributed Hybrid Transactional and Analytical Processing (HTAP) SQL database
compatible with MySQL.

- **Tier**: `T1` (`_lib/databases/tidb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `tidb`, `distributed-sql`, `mysql-compatible`, `database`

## Usage

```sh
# Install and manage the tidb service daemon
./libscript.sh install tidb latest
./libscript.sh start tidb
./libscript.sh status tidb
./libscript.sh logs tidb
./libscript.sh stop tidb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install tidb latest
.\libscript.cmd start tidb
.\libscript.cmd status tidb
.\libscript.cmd stop tidb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tidb/<version>`
  (default `~/.libscript/tidb/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TIDB_INSTALL_METHOD` (or global
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

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TIDB_INSTALL_METHOD` | How to install tidb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TIDB_VERSION`        | Specific version of tidb to install.                                                                                                          | `latest`           | latest, lts      |
| `TIDB_DOWNLOAD_URL`   | Override URL for downloading tidb binary or archive artifacts.                                                                                | `none`             |                  |
| `TIDB_RELEASES_URL`   | Override URL for querying tidb available remote releases.                                                                                     | `none`             |                  |
| `TIDB_LISTEN_PORT`    | TCP port on which the tidb service listens.                                                                                                   | `4000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
