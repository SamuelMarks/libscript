# freertos

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `freertos` component (part
of `_kernel`) within the LibScript ecosystem. FreeRTOS C11 real-time kernel source manager,
FreeRTOSConfig.h synthesizer, and multi-architecture firmware/simulator builder.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **FreeRTOS Real-Time
Kernel**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install freertos
libscript uninstall freertos
```

**Start / Stop (if configured as a background service):**

```sh
libscript start freertos
libscript stop freertos
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker freertos
```

_Note: On Unix environments, you can also use `./cli.sh install freertos`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                    | Default                              | Aliases/Examples        |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                    | `none`                               | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                            | `none`                               |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                      | `none`                               |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                       | `none`                               |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                      | `none`                               |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                              | `none`                               |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                            | `0`                                  |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                             | `0`                                  |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                        | `0`                                  |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                      | `none`                               |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                             | `none`                               |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                           | `9`                                  |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                              | `none`                               |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                            | `none`                               |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                      | `none`                               |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                   | `none`                               |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                         | `none`                               |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                  | `none`                               |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                         | `none`                               |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                              | `none`                               |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                           | `none`                               |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                         | `none`                               |                         |
| `LIBSCRIPT_RTOS_BOARD`          | Target Zephyr board or FreeRTOS BSP/simulator port identifier (e.g., qemu_x86_64, qemu_cortex_m3, qemu_riscv64, mps2_an385, riscv_virt, posix_gcc, win32_sim). | `none`                               |                         |
| `LIBSCRIPT_RTOS_HYBRID_POD`     | Flag (0 or 1) enabling hybrid multi-node cloud/unikernel + RTOS edge pod decomposition when multi-process services accompany RTOS targets.                     | `0`                                  |                         |
| `LIBSCRIPT_RTOS_MCUBOOT`        | Flag (0 or 1) enabling MCUboot slot offset compilation and cryptographic imgtool firmware signing.                                                             | `0`                                  |                         |
| `LIBSCRIPT_RTOS_RUNNER`         | Target runner selected by payloads/schedulers/rtos_firmware.{sh,cmd} (qemu, renode, or openocd).                                                               | `qemu`                               |                         |
| `FREERTOS_INSTALL_METHOD`       | How to install freertos. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source.              | `libscript_native`                   |                         |
| `FREERTOS_VERSION`              | Specific version of freertos to install.                                                                                                                       | `11.1.0`                             | latest, lts             |
| `FREERTOS_DOWNLOAD_URL`         | Override URL for downloading freertos binary or archive artifacts.                                                                                             | `none`                               |                         |
| `FREERTOS_RELEASES_URL`         | Override URL for querying freertos available remote releases.                                                                                                  | `none`                               |                         |
| `FREERTOS_PORT`                 | Target FreeRTOS port/BSP identifier (mps2_an385, riscv_virt, qemu_cortex_a53, posix_gcc, win32_sim).                                                           | `mps2_an385`                         |                         |
| `FREERTOS_HEAP_IMPL`            | FreeRTOS dynamic memory allocator scheme (heap_1, heap_2, heap_3, heap_4, heap_5, static_only).                                                                | `heap_4`                             |                         |
| `FREERTOS_TICK_RATE_HZ`         | FreeRTOS scheduler tick interrupt frequency in Hz (configTICK_RATE_HZ).                                                                                        | `1000`                               |                         |
| `FREERTOS_TOTAL_HEAP_BYTES`     | FreeRTOS heap pool capacity in bytes (configTOTAL_HEAP_SIZE).                                                                                                  | `32768`                              |                         |
| `FREERTOS_MAX_PRIORITIES`       | Maximum number of preemptive FreeRTOS task priorities (configMAX_PRIORITIES).                                                                                  | `8`                                  |                         |
| `FREERTOS_MINIMAL_STACK_WORDS`  | Minimal per-task stack depth in machine words (configMINIMAL_STACK_SIZE).                                                                                      | `128`                                |                         |
| `FREERTOS_USE_PREEMPTION`       | Enable preemptive scheduling (1) or cooperative scheduling (0).                                                                                                | `1`                                  |                         |
| `FREERTOS_USE_TICKLESS_IDLE`    | Enable low-power tickless idle mode (configUSE_TICKLESS_IDLE).                                                                                                 | `0`                                  |                         |
| `FREERTOS_NUMBER_OF_CORES`      | SMP core count configured via configNUMBER_OF_CORES.                                                                                                           | `1`                                  |                         |
| `FREERTOS_ENABLE_MPU`           | Enable Memory Protection Unit wrappers (configENABLE_MPU).                                                                                                     | `0`                                  |                         |
| `FREERTOS_COMPILER`             | Compiler backend selector (default, gcc, clang, tcc, edgcpp, msvc, custom-cc).                                                                                 | `default`                            |                         |
| `FREERTOS_COMPARE_COMPILERS`    | Compilers evaluated by _lib/kernel/freertos/compare_compilers.{sh,cmd}.                                                                                        | `default gcc clang edgcpp custom-cc` |                         |
| `FREERTOS_KERNEL_PATH`          | Active FreeRTOS-Kernel source directory exported by env.{sh,cmd}.                                                                                              | ``                                   |                         |
| `FREERTOS_FETCH_FULL_SOURCE`    | When set to 1, downloads and extracts the upstream FreeRTOS-Kernel release archive.                                                                            | `0`                                  |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
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
