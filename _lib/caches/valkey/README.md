# Valkey

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `valkey` component (part
of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**Valkey**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of Valkey, and it can be invoked seamlessly
from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this Valkey component as a foundational building block to
provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

You can install, start, stop, package, and uninstall valkey using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install valkey

./cli.sh install valkey

./libscript.sh start valkey
./cli.sh start valkey

./libscript.sh stop valkey
./cli.sh stop valkey

./libscript.sh package-as docker valkey
./cli.sh package-as docker valkey

./libscript.sh uninstall valkey
./cli.sh uninstall valkey
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install valkey

:: Local CLI
cli.cmd install valkey

:: Start and Stop
libscript.cmd start valkey
cli.cmd start valkey

libscript.cmd stop valkey
cli.cmd stop valkey

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi valkey
cli.cmd package-as msi valkey

:: Uninstall
libscript.cmd uninstall valkey
cli.cmd uninstall valkey
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                            | Default            | Aliases/Examples        |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`       | Target root filesystem staging path when provisioning chroots or OS images.                                                                                            | `none`             | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`          | Target CPU architecture when cross-compiling or building OS images.                                                                                                    | `none`             |                         |
| `LIBSCRIPT_TARGET_LIBC`          | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                              | `none`             |                         |
| `LIBSCRIPT_TARGET_OS`            | Target operating system identifier when provisioning or cross-compiling.                                                                                               | `none`             |                         |
| `LIBSCRIPT_HOST_ROOT`            | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                              | `none`             |                         |
| `LIBSCRIPT_STAGE`                | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                      | `none`             |                         |
| `LIBSCRIPT_IMAGE_BUILD`          | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                    | `0`                |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`   | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                     | `0`                |                         |
| `LIBSCRIPT_ALLOW_STUB`           | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                                | `0`                |                         |
| `LIBSCRIPT_VM_WORKER`            | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                              | `none`             |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK`  | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                     | `none`             |                         |
| `LIBSCRIPT_RELEASEVER`           | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                   | `9`                |                         |
| `LIBSCRIPT_SYSTEMD_DIR`          | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                      | `none`             |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`      | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                    | `none`             |                         |
| `LIBSCRIPT_ETC_DIR`              | Override root configuration directory for system service config files (defaults to /etc).                                                                              | `none`             |                         |
| `LIBSCRIPT_INITD_DIR`            | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                           | `none`             |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`      | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                 | `none`             |                         |
| `LIBSCRIPT_RUN_DIR`              | Override runtime PID/socket directory (defaults to /var/run).                                                                                                          | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`        | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                 | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`        | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                      | `none`             |                         |
| `LIBSCRIPT_HOME_BASE`            | Base parent directory for user home directories (defaults to /home).                                                                                                   | `none`             |                         |
| `LIBSCRIPT_ROOT_HOME`            | Root user home directory override (defaults to /root).                                                                                                                 | `none`             |                         |
| `VALKEY_VERSION`                 | Specific version of Valkey to install                                                                                                                                  | `latest`           |                         |
| `VALKEY_BUILD_DIR`               | Directory to build valkey from                                                                                                                                         | `none`             |                         |
| `LIBSCRIPT_LISTEN_PORT`          | Global port to listen on                                                                                                                                               | `none`             |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`       | Global address to listen on                                                                                                                                            | `none`             |                         |
| `LIBSCRIPT_LISTEN_SOCKET`        | Global unix socket to listen on                                                                                                                                        | `none`             |                         |
| `VALKEY_LISTEN_PORT`             | Port for VALKEY to listen on                                                                                                                                           | `none`             |                         |
| `VALKEY_LISTEN_ADDRESS`          | Address for VALKEY to listen on                                                                                                                                        | `none`             |                         |
| `VALKEY_LISTEN_SOCKET`           | Unix socket for VALKEY to listen on                                                                                                                                    | `none`             |                         |
| `VALKEY_DATA_DIR`                | Directory for Valkey data                                                                                                                                              | `none`             |                         |
| `REDIS_DATA_DIR`                 | Directory for Redis/Valkey persistent data (alias for VALKEY_DATA_DIR)                                                                                                 | `none`             |                         |
| `VALKEY_SERVICE_RUN_AS_USER`     | Windows local user account to run the service (leave empty for Network Service)                                                                                        | `none`             |                         |
| `VALKEY_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable)                                                                                                                    | `none`             |                         |
| `VALKEY_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations)                                                                                                | `libscript_valkey` |                         |
| `VALKEY_INSTALL_METHOD`          | How to install VALKEY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                         |
| `VALKEY_BUILD_FROM_SOURCE`       | Flag (0 or 1) to force compiling valkey from source.                                                                                                                   | `none`             |                         |
| `VALKEY_DOWNLOAD_URL`            | Override URL for downloading valkey binary or archive artifacts.                                                                                                       | `none`             |                         |
| `VALKEY_RELEASES_URL`            | Override URL for querying valkey available remote releases.                                                                                                            | `none`             |                         |

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
