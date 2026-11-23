# DuckDB (`_lib/databases/duckdb/`)

## Overview

An in-process SQL OLAP database management system.

- **Tier**: `T1` (`_lib/databases/duckdb/`)
- **Capabilities**: `userland-package`, `sysroot-library`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/duckdb/<version>)
./libscript.sh ls-remote duckdb
./libscript.sh install duckdb latest
./libscript.sh use duckdb latest
./libscript.sh which duckdb
./_lib/databases/duckdb/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote duckdb
.\libscript.cmd install duckdb latest
.\libscript.cmd use duckdb latest
.\libscript.cmd which duckdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/duckdb/<version>`
  (default `~/.libscript/duckdb/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `DUCKDB_INSTALL_METHOD` (or global
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

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DUCKDB_INSTALL_METHOD` | Installation strategy for duckdb: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `DUCKDB_DOWNLOAD_URL`   | Override URL for downloading duckdb binary or archive artifacts.                                                                                         | `none`             |                  |
| `DUCKDB_RELEASES_URL`   | Override URL for querying duckdb available remote releases.                                                                                              | `none`             |                  |
| `DUCKDB_VERSION`        | Specific version of duckdb to install (e.g., latest, lts, or exact version).                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
