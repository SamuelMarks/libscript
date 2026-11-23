# Odoo

## Usage

This document describes the `Odoo` component within the LibScript ecosystem. This module installs
Odoo alongside a webserver and a database (typically PostgreSQL).

It works both as a local version manager and can be invoked from the global version manager
`libscript`. Furthermore, this component can be used by libscript to build bigger stacks by
composing it with caching layers, load balancers, or other services.

You can manage Odoo using the global `libscript` CLI or local scripts.

- **Install:** `libscript install odoo`
- **Uninstall:** `libscript uninstall odoo`
- **Start:** `libscript start odoo`
- **Stop:** `libscript stop odoo`
- **Package:** `libscript package-as docker odoo` (or `msi`, `docker_compose`, etc.)

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                             | Default     |
| :------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------------- | :---------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                             | `-`         |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                     | `-`         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                               | `-`         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                | `-`         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                               | `-`         |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                           | `-`         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.     | `0`         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.      | `0`         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent. | `0`         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.               | `-`         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                      | `-`         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                    | `9`         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                       | `-`         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                     | `-`         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                               | `-`         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                            | `-`         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                  | `-`         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                           | `-`         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                  | `-`         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                       | `-`         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                    | `-`         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                  | `-`         |
| `ODOO_DB_TYPE`                  | Database backend engine for Odoo (defaults to postgres).                                                                                | `-`         |
| `ODOO_LISTEN`                   | HTTP bind address:port or socket exposed by the Odoo reverse proxy.                                                                     | `-`         |
| `ODOO_VERSION`                  | Target Odoo release branch or version (e.g., 17.0, 18.0, latest) to install.                                                            | `-`         |
| `ODOO_DB_USER`                  | PostgreSQL role used by Odoo to manage ERP databases.                                                                                   | `-`         |
| `ODOO_DB_HOST`                  | Hostname or socket directory of the PostgreSQL server backing Odoo.                                                                     | `-`         |
| `ODOO_WEBSERVER`                | Reverse-proxy web server fronting Odoo HTTP and longpolling ports (e.g., nginx, caddy).                                                 | `-`         |
| `ODOO_WWWROOT`                  | Filesystem installation and addons directory for the Odoo application.                                                                  | `-`         |
| `ODOO_SERVER_NAME`              | Public virtual host domain name configured for Odoo.                                                                                    | `-`         |
| `ODOO_DB_NAME`                  | Default PostgreSQL database name initialized for Odoo.                                                                                  | `-`         |
| `ODOO_DB_PASS`                  | Password authenticating the Odoo PostgreSQL database role.                                                                              | `-`         |
| `ODOO_DB_PORT`                  | TCP port of the PostgreSQL server backing Odoo (defaults to 5432).                                                                      | `-`         |
| `ODOO_PORT`                     | Internal HTTP service port bound by the Odoo server daemon (defaults to 8069).                                                          | `-`         |
| `db_strategy`                   | Database provisioning strategy (local managed PostgreSQL vs remote connection).                                                         | `local`     |
| `db_host`                       | Database connection host.                                                                                                               | `127.0.0.1` |
| `db_name`                       | Database name.                                                                                                                          | `odoo`      |
| `db_url`                        | Full database connection string or URL.                                                                                                 | `-`         |
| `ODOO_PHP_FPM_LISTEN`           | Optional upstream FastCGI/proxy listen endpoint associated with Odoo auxiliary routes.                                                  | `-`         |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/python`: Python runtime and Odoo application framework
- `_lib/databases/postgres`: PostgreSQL database server
- `_lib/web-servers/nginx` (or `caddy`, `httpd`): Reverse proxy and static file server
