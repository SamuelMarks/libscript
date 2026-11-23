# JBoss Application Server (`_lib/app-servers/jboss/`)

## Overview

JBoss EAP / WildFly upstream Jakarta EE application server runtime and jboss-cli management tool.

- **Tier**: `T1` (`_lib/app-servers/jboss/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `jboss`, `jakarta-ee`, `app-server`

## Usage

```sh
# Install and manage the jboss service daemon
./libscript.sh install jboss latest
./libscript.sh start jboss
./libscript.sh status jboss
./libscript.sh logs jboss
./libscript.sh stop jboss
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install jboss latest
.\libscript.cmd start jboss
.\libscript.cmd status jboss
.\libscript.cmd stop jboss
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/jboss/<version>`
  (default `~/.libscript/jboss/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `JBOSS_INSTALL_METHOD` (or global
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

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `JBOSS_INSTALL_METHOD` | How to install jboss. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `JBOSS_VERSION`        | Specific version of jboss to install.                                                                                                          | `latest`           | latest, lts      |
| `JBOSS_DOWNLOAD_URL`   | Override URL for downloading jboss binary or archive artifacts.                                                                                | `none`             |                  |
| `JBOSS_RELEASES_URL`   | Override URL for querying jboss available remote releases.                                                                                     | `none`             |                  |
| `JBOSS_LISTEN_PORT`    | TCP port on which the jboss service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
