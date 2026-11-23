# WildFly (`_lib/app-servers/wildfly/`)

## Overview

Flexible, lightweight, managed Jakarta EE and MicroProfile application runtime.

- **Tier**: `T1` (`_lib/app-servers/wildfly/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `wildfly`, `jakarta-ee`, `app-server`

## Usage

```sh
# Install and manage the wildfly service daemon
./libscript.sh install wildfly latest
./libscript.sh start wildfly
./libscript.sh status wildfly
./libscript.sh logs wildfly
./libscript.sh stop wildfly
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install wildfly latest
.\libscript.cmd start wildfly
.\libscript.cmd status wildfly
.\libscript.cmd stop wildfly
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/wildfly/<version>`
  (default `~/.libscript/wildfly/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `WILDFLY_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `WILDFLY_INSTALL_METHOD` | How to install wildfly. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `WILDFLY_VERSION`        | Specific version of wildfly to install.                                                                                                          | `latest`           | latest, lts      |
| `WILDFLY_DOWNLOAD_URL`   | Override URL for downloading wildfly binary or archive artifacts.                                                                                | `none`             |                  |
| `WILDFLY_RELEASES_URL`   | Override URL for querying wildfly available remote releases.                                                                                     | `none`             |                  |
| `WILDFLY_LISTEN_PORT`    | TCP port on which the wildfly service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
