# unikernel_pod

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `unikernel_pod` component
(part of `_orchestration`) within the LibScript ecosystem. Decomposes multi-daemon component stacks
into isolated single-process unikernel appliances with virtual bridge networking and service
discovery.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Unikernel Pod Composer**.
It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install unikernel_pod
libscript uninstall unikernel_pod
```

**Start / Stop (if configured as a background service):**

```sh
libscript start unikernel_pod
libscript stop unikernel_pod
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker unikernel_pod
```

_Note: On Unix environments, you can also use `./cli.sh install unikernel_pod`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                    | Default            | Aliases/Examples        |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                    | `none`             | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                            | `none`             |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                      | `none`             |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                       | `none`             |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                      | `none`             |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                              | `none`             |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                            | `0`                |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                             | `0`                |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                        | `0`                |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                      | `none`             |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                             | `none`             |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                           | `9`                |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                              | `none`             |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                            | `none`             |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                      | `none`             |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                   | `none`             |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                         | `none`             |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                  | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                         | `none`             |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                              | `none`             |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                           | `none`             |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                         | `none`             |                         |
| `LIBSCRIPT_RTOS_BOARD`          | Target Zephyr board or FreeRTOS BSP/simulator port identifier (e.g., qemu_x86_64, qemu_cortex_m3, qemu_riscv64, mps2_an385, riscv_virt, posix_gcc, win32_sim). | `none`             |                         |
| `LIBSCRIPT_RTOS_HYBRID_POD`     | Flag (0 or 1) enabling hybrid multi-node cloud/unikernel + RTOS edge pod decomposition when multi-process services accompany RTOS targets.                     | `0`                |                         |
| `LIBSCRIPT_RTOS_MCUBOOT`        | Flag (0 or 1) enabling MCUboot slot offset compilation and cryptographic imgtool firmware signing.                                                             | `0`                |                         |
| `LIBSCRIPT_RTOS_RUNNER`         | Target runner selected by payloads/schedulers/rtos_firmware.{sh,cmd} (qemu, renode, or openocd).                                                               | `qemu`             |                         |
| `UNIKERNEL_POD_INSTALL_METHOD`  | How to install unikernel_pod. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source.         | `libscript_native` |                         |
| `UNIKERNEL_POD_VERSION`         | Specific version of unikernel_pod to install.                                                                                                                  | `1.0.0`            | latest, lts             |
| `UNIKERNEL_POD_DOWNLOAD_URL`    | Override URL for downloading unikernel_pod binary or archive artifacts.                                                                                        | `none`             |                         |
| `UNIKERNEL_POD_RELEASES_URL`    | Override URL for querying unikernel_pod available remote releases.                                                                                             | `none`             |                         |
| `UNIKERNEL_POD_VMM`             | Target virtual machine monitor for multi-unikernel pod synthesis (qemu, firecracker, cloud-hypervisor, bhyve, solo5-hvt).                                      | `qemu`             |                         |
| `UNIKERNEL_POD_SUBNET`          | IPv4 /24 prefix assigned deterministically across decomposed unikernel pod appliances.                                                                         | `172.30.0`         |                         |
| `UNIKERNEL_POD_OUT_DIR`         | Output directory where decomposed unikernel appliance images and launch scripts are written.                                                                   | `none`             |                         |
| `UNIKERNEL_POD_DAEMONS`         | Comma-separated daemon component names decomposed into isolated single-process unikernel appliances.                                                           | `none`             | LIBSCRIPT_POD_DAEMONS   |

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
