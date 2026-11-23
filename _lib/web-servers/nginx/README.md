# Nginx (`_lib/web-servers/nginx/`)

## Overview

A high-performance HTTP and reverse proxy server, as well as a mail proxy server.

- **Tier**: `T1` (`_lib/web-servers/nginx/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `web-server`, `reverse-proxy`, `nginx`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the nginx service daemon
./libscript.sh install nginx latest
./libscript.sh start nginx
./libscript.sh status nginx
./libscript.sh logs nginx
./libscript.sh stop nginx
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install nginx latest
.\libscript.cmd start nginx
.\libscript.cmd status nginx
.\libscript.cmd stop nginx
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/nginx/<version>`
  (default `~/.libscript/nginx/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `NGINX_INSTALL_METHOD` (or global
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
| `NGINX_INSTALL_METHOD`          | Installation strategy for nginx: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system`          |                  |
| `NGINX_WWWROOT_NAME`            | The server_name or domain (e.g., example.com) to serve.                                                                                                 | `none`            |                  |
| `NGINX_WWWROOT_PATH`            | The absolute path to the static document root to serve.                                                                                                 | `none`            |                  |
| `NGINX_WWWROOT_LISTEN`          | The HTTP port Nginx should listen on (defaults to 80).                                                                                                  | `80`              |                  |
| `NGINX_SERVERS_ROOT`            | Directory containing per-site Nginx virtual host configuration files.                                                                                   | `none`            |                  |
| `LIBSCRIPT_LISTEN_PORT_SECURE`  | Global secure port to listen on                                                                                                                         | `none`            |                  |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                | `none`            |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                             | `none`            |                  |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                         | `none`            |                  |
| `NGINX_LISTEN_PORT_SECURE`      | Secure port for NGINX to listen on                                                                                                                      | `none`            |                  |
| `NGINX_LISTEN_PORT`             | Port for NGINX to listen on                                                                                                                             | `none`            |                  |
| `NGINX_LISTEN_ADDRESS`          | Address for NGINX to listen on                                                                                                                          | `none`            |                  |
| `NGINX_LISTEN_SOCKET`           | Unix socket for NGINX to listen on                                                                                                                      | `none`            |                  |
| `NGINX_SERVICE_RUN_AS_USER`     | Windows local user account to run the service (leave empty for Network Service)                                                                         | `none`            |                  |
| `NGINX_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable)                                                                                                     | `none`            |                  |
| `NGINX_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations)                                                                                 | `libscript_nginx` |                  |
| `NGINX_HTTPS_ALWAYS`            | Whether to always redirect to HTTPS.                                                                                                                    | `none`            |                  |
| `NGINX_VARS`                    | Additional variables.                                                                                                                                   | `none`            |                  |
| `NGINX_LOCATION_EXPR`           | Nginx location expression.                                                                                                                              | `none`            |                  |
| `NGINX_VERSION`                 | Version of Nginx to install                                                                                                                             | `latest`          |                  |
| `NGINX_DOWNLOAD_URL`            | Override URL for downloading nginx binary or archive artifacts.                                                                                         | `none`            |                  |
| `NGINX_FRAGMENT_CONF`           | Path (absolute or relative to LIBSCRIPT_ROOT_DIR) to a custom Nginx location/server configuration template fragment.                                    | `none`            |                  |
| `NGINX_LISTEN`                  | Listen endpoint (address:port or socket) for nginx.                                                                                                     | `none`            |                  |
| `NGINX_PHP_FPM_LISTEN`          | Listen endpoint (address:port or socket) for nginx.                                                                                                     | `none`            |                  |
| `NGINX_RELEASES_URL`            | Override URL for querying nginx available remote releases.                                                                                              | `none`            |                  |
| `NGINX_SERVER_NAME`             | Virtual host server_name directive (domain or IP) written into generated Nginx site configurations.                                                     | `none`            |                  |
| `NGINX_WWWROOT`                 | Document root filesystem directory served by the generated Nginx virtual host or location block.                                                        | `none`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
