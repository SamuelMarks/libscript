# Apache HTTP Server (`_lib/web-servers/apache/`)

## Overview

Apache HTTP Server (apachectl / apache2) modular, cross-platform web server recipe.

- **Tier**: `T1` (`_lib/web-servers/apache/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `web-server`, `apache`, `apache2`, `apachectl`
- **Conflicts With**: `httpd`

## Usage

```sh
# Install and manage the apache service daemon
./libscript.sh install apache latest
./libscript.sh start apache
./libscript.sh status apache
./libscript.sh logs apache
./libscript.sh stop apache
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install apache latest
.\libscript.cmd start apache
.\libscript.cmd status apache
.\libscript.cmd stop apache
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/apache/<version>`
  (default `~/.libscript/apache/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `APACHE_INSTALL_METHOD` (or global
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

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `APACHE_INSTALL_METHOD` | How to install apache. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `APACHE_VERSION`        | Specific version of apache to install.                                                                                                          | `latest` | latest, lts      |
| `APACHE_DOWNLOAD_URL`   | Override URL for downloading apache binary or archive artifacts.                                                                                | `none`   |                  |
| `APACHE_RELEASES_URL`   | Override URL for querying apache available remote releases.                                                                                     | `none`   |                  |
| `APACHE_LISTEN_PORT`    | TCP port on which the apache service listens.                                                                                                   | `80`     |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
