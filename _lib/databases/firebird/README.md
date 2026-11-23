# Firebird SQL (`_lib/databases/firebird/`)

## Overview

Open-source relational SQL database management system offering ANSI SQL standard compliance and
stored procedures.

- **Tier**: `T1` (`_lib/databases/firebird/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `firebird`, `sql-database`, `database`

## Usage

```sh
# Install and manage the firebird service daemon
./libscript.sh install firebird latest
./libscript.sh start firebird
./libscript.sh status firebird
./libscript.sh logs firebird
./libscript.sh stop firebird
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install firebird latest
.\libscript.cmd start firebird
.\libscript.cmd status firebird
.\libscript.cmd stop firebird
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/firebird/<version>`
  (default `~/.libscript/firebird/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `FIREBIRD_INSTALL_METHOD` (or global
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
| `FIREBIRD_INSTALL_METHOD` | How to install firebird. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `FIREBIRD_VERSION`        | Specific version of firebird to install.                                                                                                          | `latest` | latest, lts      |
| `FIREBIRD_DOWNLOAD_URL`   | Override URL for downloading firebird binary or archive artifacts.                                                                                | `none`   |                  |
| `FIREBIRD_RELEASES_URL`   | Override URL for querying firebird available remote releases.                                                                                     | `none`   |                  |
| `FIREBIRD_LISTEN_PORT`    | TCP port on which the firebird service listens.                                                                                                   | `3050`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
