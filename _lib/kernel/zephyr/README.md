# Zephyr RTOS Kernel (`_lib/kernel/zephyr/`)

## Overview

Zephyr Real-Time Operating System kernel source manager, Kconfig/Devicetree synthesizer, and
multi-board firmware builder.

- **Tier**: `T2` (`_lib/kernel/zephyr/`)
- **Capabilities**: `sysroot-package`, `kernel-image`
- **Provides Virtual Capabilities**: `zephyr-kernel`, `zephyr-lts`, `zephyr-mainline`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install zephyr latest
./libscript.sh zephyr --help
./_lib/kernel/zephyr/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd zephyr --help
.\_lib\kernel\zephyr\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `ZEPHYR_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                    | Default                                | Aliases/Examples        |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                    | `none`                                 | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                            | `none`                                 |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                      | `none`                                 |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                       | `none`                                 |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                      | `none`                                 |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                  | `none`                                 |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                            | `0`                                    |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                             | `0`                                    |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                        | `0`                                    |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                      | `none`                                 |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                             | `none`                                 |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                           | `9`                                    |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                              | `none`                                 |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                            | `none`                                 |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                      | `none`                                 |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                   | `none`                                 |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                         | `none`                                 |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                  | `none`                                 |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                         | `none`                                 |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                              | `none`                                 |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                           | `none`                                 |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                         | `none`                                 |                         |
| `LIBSCRIPT_RTOS_BOARD`          | Target Zephyr board or FreeRTOS BSP/simulator port identifier (e.g., qemu_x86_64, qemu_cortex_m3, qemu_riscv64, mps2_an385, riscv_virt, posix_gcc, win32_sim). | `none`                                 |                         |
| `LIBSCRIPT_RTOS_HYBRID_POD`     | Flag (0 or 1) enabling hybrid multi-node cloud/unikernel + RTOS edge pod decomposition when multi-process services accompany RTOS targets.                     | `0`                                    |                         |
| `LIBSCRIPT_RTOS_MCUBOOT`        | Flag (0 or 1) enabling MCUboot slot offset compilation and cryptographic imgtool firmware signing.                                                             | `0`                                    |                         |
| `LIBSCRIPT_RTOS_RUNNER`         | Target runner selected by workloads/schedulers/rtos_firmware.{sh,cmd} (qemu, renode, or openocd).                                                              | `qemu`                                 |                         |
| `ZEPHYR_INSTALL_METHOD`         | How to install zephyr. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source.                | `libscript_native`                     |                         |
| `ZEPHYR_VERSION`                | Specific version of zephyr to install.                                                                                                                         | `3.7.0`                                | latest, lts             |
| `ZEPHYR_DOWNLOAD_URL`           | Override URL for downloading zephyr binary or archive artifacts.                                                                                               | `none`                                 |                         |
| `ZEPHYR_RELEASES_URL`           | Override URL for querying zephyr available remote releases.                                                                                                    | `none`                                 |                         |
| `ZEPHYR_BOARD`                  | Target Zephyr board identifier (qemu_x86_64, qemu_cortex_a53, qemu_cortex_m3, qemu_riscv32, qemu_riscv64, native_sim, native_sim_64).                          | `qemu_x86_64`                          |                         |
| `ZEPHYR_KCONFIG_FRAGMENTS`      | Comma-separated Kconfig fragment filenames or paths merged into prj.conf/.config.                                                                              | `minimal_footprint.conf,picolibc.conf` |                         |
| `ZEPHYR_DTS_OVERLAYS`           | Comma-separated Devicetree .overlay paths merged during firmware synthesis.                                                                                    | ``                                     |                         |
| `ZEPHYR_TOOLCHAIN_VARIANT`      | Zephyr CMake toolchain variant (zephyr, llvm, gnuarmemb, cross-compile, host).                                                                                 | `zephyr`                               |                         |
| `ZEPHYR_COMPILER`               | LibScript compiler backend selector (default, gcc, clang, edgcpp, custom-cc).                                                                                  | `default`                              |                         |
| `ZEPHYR_USE_WEST`               | When set to 1, invokes west build instead of direct rootless CMake + Ninja.                                                                                    | `0`                                    |                         |
| `ZEPHYR_COMPARE_COMPILERS`      | Space- or comma-separated list of compilers evaluated by compare_compilers.{sh,cmd}.                                                                           | `default gcc clang edgcpp custom-cc`   |                         |
| `ZEPHYR_BASE`                   | Root path of the active Zephyr RTOS source tree exported by env.{sh,cmd}.                                                                                      | `none`                                 |                         |
| `ZEPHYR_SDK_INSTALL_DIR`        | Isolated Zephyr SDK directory path exported to CMake.                                                                                                          | `none`                                 |                         |
| `ZEPHYR_FETCH_FULL_SOURCE`      | When set to 1, downloads and extracts the full upstream Zephyr source tarball during install.                                                                  | `0`                                    |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
