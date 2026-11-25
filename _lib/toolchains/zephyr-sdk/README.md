# Zephyr SDK (`_lib/toolchains/zephyr-sdk/`)

## Overview

Official Zephyr RTOS cross-compilation SDK bundling bare-metal GCC/LLVM toolchains and host
utilities across Linux, macOS, and Windows.

- **Tier**: `T1` (`_lib/toolchains/zephyr-sdk/`)
- **Capabilities**: `userland-package`, `cross-toolchain`
- **Provides Virtual Capabilities**: `zephyr-sdk`, `zephyr-toolchain`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/zephyr-sdk/<version>)
./libscript.sh ls-remote zephyr-sdk
./libscript.sh install zephyr-sdk latest
./libscript.sh use zephyr-sdk latest
./libscript.sh which zephyr-sdk
./_lib/toolchains/zephyr-sdk/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote zephyr-sdk
.\libscript.cmd install zephyr-sdk latest
.\libscript.cmd use zephyr-sdk latest
.\libscript.cmd which zephyr-sdk
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/zephyr-sdk/<version>`
  (default `~/.libscript/zephyr-sdk/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `ZEPHYR_SDK_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                  | Default                      | Aliases/Examples        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                  | `none`                       | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                          | `none`                       |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                    | `none`                       |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                     | `none`                       |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                    | `none`                       |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                | `none`                       |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                          | `0`                          |                         |
| `LIBSCRIPT_DOS_STRATUM`         | Active DOS kernel capability stratum during sysroot staging (dos16-fcb for MS-DOS 1.25, dos16-handle for MS-DOS 2.0, dos32-dpmi for MS-DOS 4.0 and FreeDOS). | `none`                       |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                           | `0`                          |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                      | `0`                          |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                    | `none`                       |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                           | `none`                       |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                         | `9`                          |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                            | `none`                       |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                          | `none`                       |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                    | `none`                       |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                 | `none`                       |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                       | `none`                       |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                | `none`                       |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                       | `none`                       |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                            | `none`                       |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                         | `none`                       |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                       | `none`                       |                         |
| `ZEPHYR_SDK_INSTALL_METHOD`     | How to install zephyr-sdk. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source.          | `libscript_native`           |                         |
| `ZEPHYR_SDK_VERSION`            | Specific version of zephyr-sdk to install.                                                                                                                   | `0.17.0`                     | latest, lts             |
| `ZEPHYR_SDK_DOWNLOAD_URL`       | Override URL for downloading zephyr-sdk binary or archive artifacts.                                                                                         | `none`                       |                         |
| `ZEPHYR_SDK_RELEASES_URL`       | Override URL for querying zephyr-sdk available remote releases.                                                                                              | `none`                       |                         |
| `ZEPHYR_SDK_ARCHS`              | Comma-separated target architectures registered inside the isolated Zephyr SDK installation.                                                                 | `arm,aarch64,x86_64,riscv64` |                         |
| `ZEPHYR_SDK_INSTALL_DIR`        | Isolated Zephyr SDK directory path exported to CMake without mutating ~/.cmake/packages.                                                                     | ``                           |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
