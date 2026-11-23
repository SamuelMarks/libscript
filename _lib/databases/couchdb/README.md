# Apache CouchDB (`_lib/databases/couchdb/`)

## Overview

Seamless multi-master syncing document database with an intuitive HTTP/JSON API and reliability
focus.

- **Tier**: `T1` (`_lib/databases/couchdb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `couchdb`, `document-store`, `database`

## Usage

```sh
# Install and manage the couchdb service daemon
./libscript.sh install couchdb latest
./libscript.sh start couchdb
./libscript.sh status couchdb
./libscript.sh logs couchdb
./libscript.sh stop couchdb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install couchdb latest
.\libscript.cmd start couchdb
.\libscript.cmd status couchdb
.\libscript.cmd stop couchdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/couchdb/<version>`
  (default `~/.libscript/couchdb/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `COUCHDB_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `COUCHDB_INSTALL_METHOD` | How to install couchdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `COUCHDB_VERSION`        | Specific version of couchdb to install.                                                                                                          | `latest` | latest, lts      |
| `COUCHDB_DOWNLOAD_URL`   | Override URL for downloading couchdb binary or archive artifacts.                                                                                | `none`   |                  |
| `COUCHDB_RELEASES_URL`   | Override URL for querying couchdb available remote releases.                                                                                     | `none`   |                  |
| `COUCHDB_LISTEN_PORT`    | TCP port on which the couchdb service listens.                                                                                                   | `5984`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
