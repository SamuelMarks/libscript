# KeyDB (`_lib/caches/keydb/`)

## Overview

High-performance multithreaded fork of Redis focusing on active-active replication and flash
storage.

- **Tier**: `T1` (`_lib/caches/keydb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `keydb`, `redis-compatible`, `kv-store`, `cache`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `sunos`

## Usage

```sh
# Install and manage the keydb service daemon
./libscript.sh install keydb latest
./libscript.sh start keydb
./libscript.sh status keydb
./libscript.sh logs keydb
./libscript.sh stop keydb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install keydb latest
.\libscript.cmd start keydb
.\libscript.cmd status keydb
.\libscript.cmd stop keydb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/keydb/<version>`
  (default `~/.libscript/keydb/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `KEYDB_INSTALL_METHOD` (or global
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

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `KEYDB_INSTALL_METHOD` | How to install keydb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `KEYDB_VERSION`        | Specific version of keydb to install.                                                                                                          | `latest` | latest, lts      |
| `KEYDB_DOWNLOAD_URL`   | Override URL for downloading keydb binary or archive artifacts.                                                                                | `none`   |                  |
| `KEYDB_RELEASES_URL`   | Override URL for querying keydb available remote releases.                                                                                     | `none`   |                  |
| `KEYDB_LISTEN_PORT`    | TCP port on which the keydb service listens.                                                                                                   | `6379`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
