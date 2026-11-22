# Redis

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `redis` component (part of
`_caches`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**Redis**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of Redis, and it can be invoked seamlessly
from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this Redis component as a foundational building block to
provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

You can install, start, stop, package, and uninstall redis using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh
./libscript.sh install redis
./cli.sh install redis

./libscript.sh start redis
./cli.sh start redis

./libscript.sh stop redis
./cli.sh stop redis

./libscript.sh package-as docker redis
./cli.sh package-as docker redis

./libscript.sh uninstall redis
./cli.sh uninstall redis
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install redis

:: Local CLI
cli.cmd install redis

:: Start and Stop
libscript.cmd start redis
cli.cmd start redis

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi redis
cli.cmd package-as msi redis

:: Uninstall
libscript.cmd uninstall redis
cli.cmd uninstall redis
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                           | Default            | Aliases/Examples        |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                           | `none`             | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                                   | `none`             |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                             | `none`             |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                              | `none`             |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                             | `none`             |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                         | `none`             |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                   | `0`                |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                    | `0`                |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                               | `0`                |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                             | `none`             |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                    | `none`             |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                  | `9`                |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                     | `none`             |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                   | `none`             |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                             | `none`             |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                          | `none`             |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                | `none`             |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                         | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                     | `none`             |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                                  | `none`             |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                                | `none`             |                         |
| `REDIS_VERSION`                 | Specific version of redis to install. Can be a numeric version or an alias.                                                                                           | `latest`           | latest, stable          |
| `REDIS_INSTALL_METHOD`          | How to install REDIS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                         |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                              | `none`             |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                           | `none`             |                         |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                       | `none`             |                         |
| `REDIS_LISTEN_PORT`             | Port for REDIS to listen on                                                                                                                                           | `6379`             |                         |
| `REDIS_REMOTE_URL`              | Remote Redis or Valkey connection string (e.g. 'redis://redis.internal:6379/0'). If set, skips local server installation.                                             | `none`             |                         |
| `REDIS_LISTEN_ADDRESS`          | Address for REDIS to listen on                                                                                                                                        | `none`             |                         |
| `REDIS_LISTEN_SOCKET`           | Unix socket for REDIS to listen on                                                                                                                                    | `none`             |                         |
| `REDIS_DATA_DIR`                | Directory for Redis persistent data                                                                                                                                   | `none`             |                         |
| `VALKEY_DATA_DIR`               | Directory for Valkey/Redis persistent data (alias for REDIS_DATA_DIR)                                                                                                 | `none`             |                         |
| `REDIS_DOWNLOAD_URL`            | Override URL for downloading redis binary or archive artifacts.                                                                                                       | `none`             |                         |
| `REDIS_LISTEN`                  | Listen endpoint (address:port or socket) for redis.                                                                                                                   | `none`             |                         |
| `REDIS_RELEASES_URL`            | Override URL for querying redis available remote releases.                                                                                                            | `none`             |                         |
| `REDIS_PORT`                    | TCP listening port configured in redis.conf for Redis server instances.                                                                                               | `6379`             |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
