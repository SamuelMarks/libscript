# Caddy (`_lib/web-servers/caddy/`)

## Overview

A powerful, enterprise-ready, open source web server with automatic HTTPS written in Go.

- **Tier**: `T1` (`_lib/web-servers/caddy/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `web-server`, `reverse-proxy`, `caddy`

## Usage

```sh
# Install and manage the caddy service daemon
./libscript.sh install caddy latest
./libscript.sh start caddy
./libscript.sh status caddy
./libscript.sh logs caddy
./libscript.sh stop caddy
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install caddy latest
.\libscript.cmd start caddy
.\libscript.cmd status caddy
.\libscript.cmd stop caddy
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/caddy/<version>`
  (default `~/.libscript/caddy/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CADDY_INSTALL_METHOD` (or global
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

| Variable                        | Description                                                                                                                                                  | Default           | Aliases/Examples        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                  | `none`            | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                          | `none`            |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                    | `none`            |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                     | `none`            |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                    | `none`            |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                | `none`            |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                          | `0`               |                         |
| `LIBSCRIPT_DOS_STRATUM`         | Active DOS kernel capability stratum during sysroot staging (dos16-fcb for MS-DOS 1.25, dos16-handle for MS-DOS 2.0, dos32-dpmi for MS-DOS 4.0 and FreeDOS). | `none`            |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                           | `0`               |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                      | `0`               |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                    | `none`            |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                           | `none`            |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                         | `9`               |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                            | `none`            |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                          | `none`            |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                    | `none`            |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                 | `none`            |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                       | `none`            |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                | `none`            |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                       | `none`            |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                            | `none`            |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                         | `none`            |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                       | `none`            |                         |
| `CADDY_INSTALL_METHOD`          | Installation strategy for caddy: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager.      | `system`          |                         |
| `CADDY_VERSION`                 | Specific version of caddy to install. Can be a numeric version or an alias.                                                                                  | `latest`          | latest, stable          |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                     | `none`            |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                  | `none`            |                         |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                              | `none`            |                         |
| `CADDY_LISTEN_PORT`             | Port for CADDY to listen on                                                                                                                                  | `none`            |                         |
| `CADDY_LISTEN_ADDRESS`          | Address for CADDY to listen on                                                                                                                               | `none`            |                         |
| `CADDY_LISTEN_SOCKET`           | Unix socket for CADDY to listen on                                                                                                                           | `none`            |                         |
| `CADDY_WWWROOT_NAME`            | The primary domain or server name (e.g., example.com) to bind the web server to.                                                                             | `none`            |                         |
| `CADDY_WWWROOT_PATH`            | The absolute path to the static site document root (where index.html resides).                                                                               | `none`            |                         |
| `CADDY_WWWROOT_LISTEN`          | The HTTP port Caddy should listen on (defaults to 80, but 443 is used automatically for HTTPS).                                                              | `80`              |                         |
| `CADDY_WWWROOT_HTTPS_PROVIDER`  | The HTTPS provider for automatic certificates. Usually 'letsencrypt' or 'zerossl' (Caddy uses both by default if not set).                                   | `none`            |                         |
| `CADDY_SERVICE_RUN_AS_USER`     | Windows local user account to run the service under (leave empty for Network Service).                                                                       | `none`            |                         |
| `CADDY_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable).                                                                                                 | `none`            |                         |
| `CADDY_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations).                                                                                     | `libscript_caddy` |                         |
| `CADDY_LISTEN`                  | Address/port to listen on.                                                                                                                                   | `none`            |                         |
| `CADDY_WWWROOT`                 | Web server root directory.                                                                                                                                   | `none`            |                         |
| `CADDY_PHP_FPM_LISTEN`          | Listen address/socket for PHP-FPM.                                                                                                                           | `none`            |                         |
| `CADDY_SERVER_NAME`             | Name of the server (e.g., example.com).                                                                                                                      | `none`            |                         |
| `CADDY_DOWNLOAD_URL`            | Override URL for downloading caddy binary or archive artifacts.                                                                                              | `none`            |                         |
| `CADDY_RELEASES_URL`            | Override URL for querying caddy available remote releases.                                                                                                   | `none`            |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
