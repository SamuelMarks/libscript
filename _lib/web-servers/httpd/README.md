# Apache HTTPD (`_lib/web-servers/httpd/`)

## Overview

The Apache HTTP Server, a secure, efficient and extensible server that provides HTTP services in
sync with the current HTTP standards.

- **Tier**: `T1` (`_lib/web-servers/httpd/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `web-server`, `apache`, `httpd`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the httpd service daemon
./libscript.sh install httpd latest
./libscript.sh start httpd
./libscript.sh status httpd
./libscript.sh logs httpd
./libscript.sh stop httpd
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install httpd latest
.\libscript.cmd start httpd
.\libscript.cmd status httpd
.\libscript.cmd stop httpd
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/httpd/<version>`
  (default `~/.libscript/httpd/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `HTTPD_INSTALL_METHOD` (or global
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

| Variable                        | Description                                                                                                                                             | Default           | Aliases/Examples |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------- |
| `HTTPD_INSTALL_METHOD`          | Installation strategy for httpd: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system`          |                  |
| `HTTPD_VERSION`                 | Specific version of httpd to install. Can be a numeric version or an alias.                                                                             | `latest`          | latest, stable   |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                | `none`            |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                             | `none`            |                  |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                         | `none`            |                  |
| `HTTPD_LISTEN_PORT`             | Port for HTTPD to listen on                                                                                                                             | `none`            |                  |
| `HTTPD_LISTEN_ADDRESS`          | Address for HTTPD to listen on                                                                                                                          | `none`            |                  |
| `HTTPD_LISTEN_SOCKET`           | Unix socket for HTTPD to listen on                                                                                                                      | `none`            |                  |
| `HTTPD_WWWROOT_NAME`            | The primary domain or server name (ServerName) for Apache to bind to.                                                                                   | `none`            |                  |
| `HTTPD_WWWROOT_PATH`            | The absolute path to the DocumentRoot directory.                                                                                                        | `none`            |                  |
| `HTTPD_WWWROOT_LISTEN`          | The HTTP port Apache should listen on (defaults to 80).                                                                                                 | `80`              |                  |
| `HTTPD_SERVICE_RUN_AS_USER`     | Windows local user account to run the Apache service under (leave empty for default).                                                                   | `none`            |                  |
| `HTTPD_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable).                                                                                            | `none`            |                  |
| `HTTPD_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations).                                                                                | `libscript_httpd` |                  |
| `HTTPD_LISTEN`                  | Address/port to listen on.                                                                                                                              | `none`            |                  |
| `HTTPD_WWWROOT`                 | Web server root directory.                                                                                                                              | `none`            |                  |
| `HTTPD_PHP_FPM_LISTEN`          | Listen address/socket for PHP-FPM.                                                                                                                      | `none`            |                  |
| `HTTPD_SERVER_NAME`             | Name of the server (e.g., example.com).                                                                                                                 | `none`            |                  |
| `HTTPD_DOWNLOAD_URL`            | Override URL for downloading httpd binary or archive artifacts.                                                                                         | `none`            |                  |
| `HTTPD_RELEASES_URL`            | Override URL for querying httpd available remote releases.                                                                                              | `none`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
