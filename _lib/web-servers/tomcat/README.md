# Apache Tomcat (`_lib/web-servers/tomcat/`)

## Overview

Open-source implementation of Jakarta Servlet, Jakarta Server Pages, and WebSocket specifications.

- **Tier**: `T1` (`_lib/web-servers/tomcat/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `tomcat`, `servlet-container`, `web-server`

## Usage

```sh
# Install and manage the tomcat service daemon
./libscript.sh install tomcat latest
./libscript.sh start tomcat
./libscript.sh status tomcat
./libscript.sh logs tomcat
./libscript.sh stop tomcat
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install tomcat latest
.\libscript.cmd start tomcat
.\libscript.cmd status tomcat
.\libscript.cmd stop tomcat
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tomcat/<version>`
  (default `~/.libscript/tomcat/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TOMCAT_INSTALL_METHOD` (or global
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

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TOMCAT_INSTALL_METHOD` | How to install tomcat. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TOMCAT_VERSION`        | Specific version of tomcat to install.                                                                                                          | `latest`           | latest, lts      |
| `TOMCAT_DOWNLOAD_URL`   | Override URL for downloading tomcat binary or archive artifacts.                                                                                | `none`             |                  |
| `TOMCAT_RELEASES_URL`   | Override URL for querying tomcat available remote releases.                                                                                     | `none`             |                  |
| `TOMCAT_LISTEN_PORT`    | TCP port on which the tomcat service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
