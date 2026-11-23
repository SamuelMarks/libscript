# SurrealDB (`_lib/databases/surrealdb/`)

## Overview

Scalable distributed multi-model cloud database supporting relational, document, graph, and vector
queries.

- **Tier**: `T1` (`_lib/databases/surrealdb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `surrealdb`, `multi-model-database`, `database`

## Usage

```sh
# Install and manage the surrealdb service daemon
./libscript.sh install surrealdb latest
./libscript.sh start surrealdb
./libscript.sh status surrealdb
./libscript.sh logs surrealdb
./libscript.sh stop surrealdb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install surrealdb latest
.\libscript.cmd start surrealdb
.\libscript.cmd status surrealdb
.\libscript.cmd stop surrealdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/surrealdb/<version>`
  (default `~/.libscript/surrealdb/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `SURREALDB_INSTALL_METHOD` (or global
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
| `SURREALDB_INSTALL_METHOD` | How to install surrealdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SURREALDB_VERSION`        | Specific version of surrealdb to install.                                                                                                          | `latest`           | latest, lts      |
| `SURREALDB_DOWNLOAD_URL`   | Override URL for downloading surrealdb binary or archive artifacts.                                                                                | `none`             |                  |
| `SURREALDB_RELEASES_URL`   | Override URL for querying surrealdb available remote releases.                                                                                     | `none`             |                  |
| `SURREALDB_LISTEN_PORT`    | TCP port on which the surrealdb service listens.                                                                                                   | `8000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
