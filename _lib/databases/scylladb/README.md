# ScyllaDB (`_lib/databases/scylladb/`)

## Overview

Ultra-low-latency C++ distributed wide-column NoSQL database compatible with Apache Cassandra and
Amazon DynamoDB.

- **Tier**: `T1` (`_lib/databases/scylladb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `scylladb`, `wide-column-store`, `cassandra-compatible`,
  `database`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `darwin`, `sunos`

## Usage

```sh
# Install and manage the scylladb service daemon
./libscript.sh install scylladb latest
./libscript.sh start scylladb
./libscript.sh status scylladb
./libscript.sh logs scylladb
./libscript.sh stop scylladb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install scylladb latest
.\libscript.cmd start scylladb
.\libscript.cmd status scylladb
.\libscript.cmd stop scylladb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/scylladb/<version>`
  (default `~/.libscript/scylladb/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `SCYLLADB_INSTALL_METHOD` (or global
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

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `SCYLLADB_INSTALL_METHOD` | How to install scylladb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `SCYLLADB_VERSION`        | Specific version of scylladb to install.                                                                                                          | `latest` | latest, lts      |
| `SCYLLADB_DOWNLOAD_URL`   | Override URL for downloading scylladb binary or archive artifacts.                                                                                | `none`   |                  |
| `SCYLLADB_RELEASES_URL`   | Override URL for querying scylladb available remote releases.                                                                                     | `none`   |                  |
| `SCYLLADB_LISTEN_PORT`    | TCP port on which the scylladb service listens.                                                                                                   | `9042`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
