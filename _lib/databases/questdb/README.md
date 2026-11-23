# QuestDB (`_lib/databases/questdb/`)

## Overview

High-throughput open-source time-series database with fast SQL, InfluxDB Line Protocol, and
PostgreSQL wire support.

- **Tier**: `T1` (`_lib/databases/questdb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `questdb`, `tsdb`, `database`

## Usage

```sh
# Install and manage the questdb service daemon
./libscript.sh install questdb latest
./libscript.sh start questdb
./libscript.sh status questdb
./libscript.sh logs questdb
./libscript.sh stop questdb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install questdb latest
.\libscript.cmd start questdb
.\libscript.cmd status questdb
.\libscript.cmd stop questdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/questdb/<version>`
  (default `~/.libscript/questdb/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `QUESTDB_INSTALL_METHOD` (or global
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
| `QUESTDB_INSTALL_METHOD` | How to install questdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `QUESTDB_VERSION`        | Specific version of questdb to install.                                                                                                          | `latest`           | latest, lts      |
| `QUESTDB_DOWNLOAD_URL`   | Override URL for downloading questdb binary or archive artifacts.                                                                                | `none`             |                  |
| `QUESTDB_RELEASES_URL`   | Override URL for querying questdb available remote releases.                                                                                     | `none`             |                  |
| `QUESTDB_LISTEN_PORT`    | TCP port on which the questdb service listens.                                                                                                   | `9000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
