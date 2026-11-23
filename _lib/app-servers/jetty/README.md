# Eclipse Jetty (`_lib/app-servers/jetty/`)

## Overview

Lightweight, highly scalable Java HTTP web server and Jakarta Servlet container.

- **Tier**: `T1` (`_lib/app-servers/jetty/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `jetty`, `servlet-container`, `app-server`

## Usage

```sh
# Install and manage the jetty service daemon
./libscript.sh install jetty latest
./libscript.sh start jetty
./libscript.sh status jetty
./libscript.sh logs jetty
./libscript.sh stop jetty
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install jetty latest
.\libscript.cmd start jetty
.\libscript.cmd status jetty
.\libscript.cmd stop jetty
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/jetty/<version>`
  (default `~/.libscript/jetty/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `JETTY_INSTALL_METHOD` (or global
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
| `JETTY_INSTALL_METHOD` | How to install jetty. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `JETTY_VERSION`        | Specific version of jetty to install.                                                                                                          | `latest`           | latest, lts      |
| `JETTY_DOWNLOAD_URL`   | Override URL for downloading jetty binary or archive artifacts.                                                                                | `none`             |                  |
| `JETTY_RELEASES_URL`   | Override URL for querying jetty available remote releases.                                                                                     | `none`             |                  |
| `JETTY_LISTEN_PORT`    | TCP port on which the jetty service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
