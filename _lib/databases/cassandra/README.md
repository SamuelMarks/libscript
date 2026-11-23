# Apache Cassandra (`_lib/databases/cassandra/`)

## Overview

Distributed wide-column NoSQL database designed to handle large amounts of data across commodity
servers with high availability.

- **Tier**: `T1` (`_lib/databases/cassandra/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `cassandra`, `wide-column-store`, `database`

## Usage

```sh
# Install and manage the cassandra service daemon
./libscript.sh install cassandra latest
./libscript.sh start cassandra
./libscript.sh status cassandra
./libscript.sh logs cassandra
./libscript.sh stop cassandra
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install cassandra latest
.\libscript.cmd start cassandra
.\libscript.cmd status cassandra
.\libscript.cmd stop cassandra
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/cassandra/<version>`
  (default `~/.libscript/cassandra/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `CASSANDRA_INSTALL_METHOD` (or global
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
| `CASSANDRA_INSTALL_METHOD` | How to install cassandra. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CASSANDRA_VERSION`        | Specific version of cassandra to install.                                                                                                          | `latest`           | latest, lts      |
| `CASSANDRA_DOWNLOAD_URL`   | Override URL for downloading cassandra binary or archive artifacts.                                                                                | `none`             |                  |
| `CASSANDRA_RELEASES_URL`   | Override URL for querying cassandra available remote releases.                                                                                     | `none`             |                  |
| `CASSANDRA_LISTEN_PORT`    | TCP port on which the cassandra service listens.                                                                                                   | `9042`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
