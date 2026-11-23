# CockroachDB (`_lib/databases/cockroachdb/`)

## Overview

Cloud-native distributed SQL database built for transactional consistency, horizontal scalability,
and survivability.

- **Tier**: `T1` (`_lib/databases/cockroachdb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `cockroachdb`, `distributed-sql`, `database`

## Usage

```sh
# Install and manage the cockroachdb service daemon
./libscript.sh install cockroachdb latest
./libscript.sh start cockroachdb
./libscript.sh status cockroachdb
./libscript.sh logs cockroachdb
./libscript.sh stop cockroachdb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install cockroachdb latest
.\libscript.cmd start cockroachdb
.\libscript.cmd status cockroachdb
.\libscript.cmd stop cockroachdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/cockroachdb/<version>` (default `~/.libscript/cockroachdb/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `COCKROACHDB_INSTALL_METHOD` (or global
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

| Variable                     | Description                                                                                                                                          | Default            | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `COCKROACHDB_INSTALL_METHOD` | How to install cockroachdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `COCKROACHDB_VERSION`        | Specific version of cockroachdb to install.                                                                                                          | `latest`           | latest, lts      |
| `COCKROACHDB_DOWNLOAD_URL`   | Override URL for downloading cockroachdb binary or archive artifacts.                                                                                | `none`             |                  |
| `COCKROACHDB_RELEASES_URL`   | Override URL for querying cockroachdb available remote releases.                                                                                     | `none`             |                  |
| `COCKROACHDB_LISTEN_PORT`    | TCP port on which the cockroachdb service listens.                                                                                                   | `26257`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
