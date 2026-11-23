# ClickHouse (`_lib/databases/clickhouse/`)

## Overview

High-performance column-oriented SQL database management system for online analytical processing
(OLAP).

- **Tier**: `T1` (`_lib/databases/clickhouse/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `clickhouse`, `olap-database`, `database`

## Usage

```sh
# Install and manage the clickhouse service daemon
./libscript.sh install clickhouse latest
./libscript.sh start clickhouse
./libscript.sh status clickhouse
./libscript.sh logs clickhouse
./libscript.sh stop clickhouse
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install clickhouse latest
.\libscript.cmd start clickhouse
.\libscript.cmd status clickhouse
.\libscript.cmd stop clickhouse
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/clickhouse/<version>`
  (default `~/.libscript/clickhouse/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `CLICKHOUSE_INSTALL_METHOD` (or global
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

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CLICKHOUSE_INSTALL_METHOD` | How to install clickhouse. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CLICKHOUSE_VERSION`        | Specific version of clickhouse to install.                                                                                                          | `latest`           | latest, lts      |
| `CLICKHOUSE_DOWNLOAD_URL`   | Override URL for downloading clickhouse binary or archive artifacts.                                                                                | `none`             |                  |
| `CLICKHOUSE_RELEASES_URL`   | Override URL for querying clickhouse available remote releases.                                                                                     | `none`             |                  |
| `CLICKHOUSE_LISTEN_PORT`    | TCP port on which the clickhouse service listens.                                                                                                   | `8123`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
