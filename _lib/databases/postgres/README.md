# PostgreSQL

## Purpose & Current State

This document provides context and technical details for the **PostgreSQL** component (part of the
`_storage` directory) within the LibScript ecolibscript_native. PostgreSQL is a powerful,
open-source object-relational database libscript_native.

This module works both as a local version manager for PostgreSQL (similar to `rvm`, `nvm`, `pyenv`,
or `uv`) and can be directly invoked from the global version manager `libscript`. Because of this
flexibility, PostgreSQL can be utilized by LibScript to provision and build bigger, more complex
software stacks (such as WordPress, Open edX, Nextcloud, etc.).

## Usage

You can install, start, stop, package, and uninstall postgres using the global `libscript` command
or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install postgres

./cli.sh install postgres

./libscript.sh start postgres
./cli.sh start postgres

./libscript.sh stop postgres
./cli.sh stop postgres

./libscript.sh package-as docker postgres
./cli.sh package-as docker postgres

./libscript.sh uninstall postgres
./cli.sh uninstall postgres
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install postgres

:: Local CLI
cli.cmd install postgres

:: Start and Stop
libscript.cmd start postgres
cli.cmd start postgres

libscript.cmd stop postgres
cli.cmd stop postgres

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi postgres
cli.cmd package-as msi postgres

:: Uninstall
libscript.cmd uninstall postgres
cli.cmd uninstall postgres
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                              | Default              | Aliases/Examples        |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`         | Target root filesystem staging path when provisioning chroots or OS images.                                                                                              | `none`               | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`            | Target CPU architecture when cross-compiling or building OS images.                                                                                                      | `none`               |                         |
| `LIBSCRIPT_TARGET_LIBC`            | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                                | `none`               |                         |
| `LIBSCRIPT_TARGET_OS`              | Target operating system identifier when provisioning or cross-compiling.                                                                                                 | `none`               |                         |
| `LIBSCRIPT_HOST_ROOT`              | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                                | `none`               |                         |
| `LIBSCRIPT_STAGE`                  | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                        | `none`               |                         |
| `LIBSCRIPT_IMAGE_BUILD`            | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                      | `0`                  |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`     | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                       | `0`                  |                         |
| `LIBSCRIPT_ALLOW_STUB`             | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                                  | `0`                  |                         |
| `LIBSCRIPT_VM_WORKER`              | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                                | `none`               |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK`    | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                       | `none`               |                         |
| `LIBSCRIPT_RELEASEVER`             | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                     | `9`                  |                         |
| `LIBSCRIPT_SYSTEMD_DIR`            | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                        | `none`               |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`        | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                      | `none`               |                         |
| `LIBSCRIPT_ETC_DIR`                | Override root configuration directory for system service config files (defaults to /etc).                                                                                | `none`               |                         |
| `LIBSCRIPT_INITD_DIR`              | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                             | `none`               |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`        | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                   | `none`               |                         |
| `LIBSCRIPT_RUN_DIR`                | Override runtime PID/socket directory (defaults to /var/run).                                                                                                            | `none`               |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`          | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                   | `none`               |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`          | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                        | `none`               |                         |
| `LIBSCRIPT_HOME_BASE`              | Base parent directory for user home directories (defaults to /home).                                                                                                     | `none`               |                         |
| `LIBSCRIPT_ROOT_HOME`              | Root user home directory override (defaults to /root).                                                                                                                   | `none`               |                         |
| `POSTGRES_VERSION`                 | Version of PostgreSQL demanded                                                                                                                                           | `none`               |                         |
| `POSTGRES_USER`                    | Username to create inside postgres                                                                                                                                       | `none`               |                         |
| `POSTGRES_PASSWORD`                | Password for created user inside postgres                                                                                                                                | `none`               |                         |
| `POSTGRES_PASSWORD_FILE`           | Password file, its contents used as password for created user inside postgres                                                                                            | `none`               |                         |
| `POSTGRES_SERVICE_USER`            | Username for superuser & system role                                                                                                                                     | `none`               |                         |
| `POSTGRES_SERVICE_PASSWORD`        | Password for postgres user; fallsback to `POSTGRES_PASSWORD`                                                                                                             | `none`               |                         |
| `POSTGRES_HOST`                    | Hostname to serve postgres from                                                                                                                                          | `none`               |                         |
| `POSTGRES_DB`                      | Database to create within postgres                                                                                                                                       | `none`               |                         |
| `LIBSCRIPT_LISTEN_PORT`            | Global port to listen on                                                                                                                                                 | `none`               |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`         | Global address to listen on                                                                                                                                              | `none`               |                         |
| `LIBSCRIPT_LISTEN_SOCKET`          | Global unix socket to listen on                                                                                                                                          | `none`               |                         |
| `POSTGRES_LISTEN_PORT`             | Port for POSTGRES to listen on                                                                                                                                           | `none`               |                         |
| `POSTGRES_LISTEN_ADDRESS`          | Address for POSTGRES to listen on                                                                                                                                        | `none`               |                         |
| `POSTGRES_LISTEN_SOCKET`           | Unix socket for POSTGRES to listen on                                                                                                                                    | `none`               |                         |
| `POSTGRES_DATA_DIR`                | Directory for PostgreSQL data cluster                                                                                                                                    | `none`               |                         |
| `PGDATA`                           | PostgreSQL data directory path (alias for POSTGRES_DATA_DIR)                                                                                                             | `none`               |                         |
| `POSTGRES_LOCALE`                  | Locale for PostgreSQL initdb (e.g. English, United States)                                                                                                               | `none`               |                         |
| `POSTGRES_SERVICE_RUN_AS_USER`     | Windows local user account to run the service (leave empty for Network Service)                                                                                          | `none`               |                         |
| `POSTGRES_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable)                                                                                                                      | `none`               |                         |
| `POSTGRES_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations)                                                                                                  | `libscript_postgres` |                         |
| `POSTGRES_SERVICE_GROUP`           | Group for PostgreSQL service.                                                                                                                                            | `none`               |                         |
| `POSTGRES_URL_VERSION`             | URL format version for PostgreSQL.                                                                                                                                       | `none`               |                         |
| `POSTGRES_URL`                     | Connection URL for PostgreSQL.                                                                                                                                           | `none`               |                         |
| `POSTGRES_INSTALL_METHOD`          | How to install POSTGRES. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`   |                         |
| `POSTGRES_DOWNLOAD_URL`            | Override URL for downloading postgres binary or archive artifacts.                                                                                                       | `none`               |                         |
| `POSTGRES_PORT`                    | TCP port on which postgres listens.                                                                                                                                      | `none`               |                         |
| `POSTGRES_RELEASES_URL`            | Override URL for querying postgres available remote releases.                                                                                                            | `none`               |                         |
| `POSTGRES_ETC_DIR`                 | Configuration directory override for PostgreSQL.                                                                                                                         | `none`               |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
