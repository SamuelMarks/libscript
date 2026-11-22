# MongoDB

## Purpose & Current State

This document provides context and technical details for the **MongoDB** component (part of the
`_storage` module) within the LibScript ecolibscript_native. MongoDB is a widely used,
document-oriented NoSQL database libscript_native.

This module works both as a local version manager for MongoDB (similar to `rvm`, `nvm`, `pyenv`, or
`uv`) and can be directly invoked from the global version manager `libscript`. By treating MongoDB
as a modular component, LibScript can use it to provision and build bigger, more complex software
stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can install, start, stop, package, and uninstall mongodb using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install mongodb

./cli.sh install mongodb

./libscript.sh start mongodb
./cli.sh start mongodb

./libscript.sh stop mongodb
./cli.sh stop mongodb

./libscript.sh package-as docker mongodb
./cli.sh package-as docker mongodb

./libscript.sh uninstall mongodb
./cli.sh uninstall mongodb
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install mongodb

:: Local CLI
cli.cmd install mongodb

:: Start and Stop
libscript.cmd start mongodb
cli.cmd start mongodb

libscript.cmd stop mongodb
cli.cmd stop mongodb

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi mongodb
cli.cmd package-as msi mongodb

:: Uninstall
libscript.cmd uninstall mongodb
cli.cmd uninstall mongodb
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                                                                             | Default             | Aliases/Examples        |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`        | Target root filesystem staging path when provisioning chroots or OS images.                                                                                             | `none`              | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`           | Target CPU architecture when cross-compiling or building OS images.                                                                                                     | `none`              |                         |
| `LIBSCRIPT_TARGET_LIBC`           | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                               | `none`              |                         |
| `LIBSCRIPT_TARGET_OS`             | Target operating system identifier when provisioning or cross-compiling.                                                                                                | `none`              |                         |
| `LIBSCRIPT_HOST_ROOT`             | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                               | `none`              |                         |
| `LIBSCRIPT_STAGE`                 | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                           | `none`              |                         |
| `LIBSCRIPT_IMAGE_BUILD`           | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                     | `0`                 |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`    | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                      | `0`                 |                         |
| `LIBSCRIPT_ALLOW_STUB`            | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                                 | `0`                 |                         |
| `LIBSCRIPT_VM_WORKER`             | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                               | `none`              |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK`   | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                      | `none`              |                         |
| `LIBSCRIPT_RELEASEVER`            | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                    | `9`                 |                         |
| `LIBSCRIPT_SYSTEMD_DIR`           | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                       | `none`              |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`       | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                     | `none`              |                         |
| `LIBSCRIPT_ETC_DIR`               | Override root configuration directory for system service config files (defaults to /etc).                                                                               | `none`              |                         |
| `LIBSCRIPT_INITD_DIR`             | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                            | `none`              |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`       | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                  | `none`              |                         |
| `LIBSCRIPT_RUN_DIR`               | Override runtime PID/socket directory (defaults to /var/run).                                                                                                           | `none`              |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`         | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                  | `none`              |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`         | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                       | `none`              |                         |
| `LIBSCRIPT_HOME_BASE`             | Base parent directory for user home directories (defaults to /home).                                                                                                    | `none`              |                         |
| `LIBSCRIPT_ROOT_HOME`             | Root user home directory override (defaults to /root).                                                                                                                  | `none`              |                         |
| `MONGODB_VERSION`                 | Specific version of mongodb to install. Can be a numeric version or an alias.                                                                                           | `latest`            | latest, stable          |
| `MONGODB_INSTALL_METHOD`          | How to install MONGODB. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`  |                         |
| `LIBSCRIPT_LISTEN_PORT`           | Global port to listen on                                                                                                                                                | `none`              |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`        | Global address to listen on                                                                                                                                             | `none`              |                         |
| `LIBSCRIPT_LISTEN_SOCKET`         | Global unix socket to listen on                                                                                                                                         | `none`              |                         |
| `MONGODB_LISTEN_PORT`             | Port for MONGODB to listen on                                                                                                                                           | `none`              |                         |
| `MONGODB_LISTEN_ADDRESS`          | Address for MONGODB to listen on                                                                                                                                        | `none`              |                         |
| `MONGODB_LISTEN_SOCKET`           | Unix socket for MONGODB to listen on                                                                                                                                    | `none`              |                         |
| `MONGODB_DATA_DIR`                | Directory for MongoDB data                                                                                                                                              | `none`              |                         |
| `MONGODB_SERVICE_RUN_AS_USER`     | Windows local user account to run the service (leave empty for Network Service)                                                                                         | `none`              |                         |
| `MONGODB_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable)                                                                                                                     | `none`              |                         |
| `MONGODB_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations)                                                                                                 | `libscript_mongodb` |                         |
| `MONGODB_DOWNLOAD_URL`            | Override URL for downloading mongodb binary or archive artifacts.                                                                                                       | `none`              |                         |
| `MONGODB_RELEASES_URL`            | Override URL for querying mongodb available remote releases.                                                                                                            | `none`              |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
