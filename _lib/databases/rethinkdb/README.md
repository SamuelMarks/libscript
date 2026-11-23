# RethinkDB (`_lib/databases/rethinkdb/`)

## Overview

Open-source distributed JSON database built for real-time changefeeds and reactive web applications.

- **Tier**: `T1` (`_lib/databases/rethinkdb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `rethinkdb`, `document-store`, `database`

## Usage

```sh
# Install and manage the rethinkdb service daemon
./libscript.sh install rethinkdb latest
./libscript.sh start rethinkdb
./libscript.sh status rethinkdb
./libscript.sh logs rethinkdb
./libscript.sh stop rethinkdb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install rethinkdb latest
.\libscript.cmd start rethinkdb
.\libscript.cmd status rethinkdb
.\libscript.cmd stop rethinkdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/rethinkdb/<version>`
  (default `~/.libscript/rethinkdb/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `RETHINKDB_INSTALL_METHOD` (or global
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

| Variable                   | Description                                                                                                                                        | Default  | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `RETHINKDB_INSTALL_METHOD` | How to install rethinkdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `RETHINKDB_VERSION`        | Specific version of rethinkdb to install.                                                                                                          | `latest` | latest, lts      |
| `RETHINKDB_DOWNLOAD_URL`   | Override URL for downloading rethinkdb binary or archive artifacts.                                                                                | `none`   |                  |
| `RETHINKDB_RELEASES_URL`   | Override URL for querying rethinkdb available remote releases.                                                                                     | `none`   |                  |
| `RETHINKDB_LISTEN_PORT`    | TCP port on which the rethinkdb service listens.                                                                                                   | `28015`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
