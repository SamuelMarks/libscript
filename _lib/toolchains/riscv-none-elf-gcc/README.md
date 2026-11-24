# RISC-V Bare-Metal GNU Toolchain (`_lib/toolchains/riscv-none-elf-gcc/`)

## Overview

Bare-metal 32/64-bit RISC-V multilib (rv32imac/rv64imac) embedded GNU cross-toolchain with newlib
and picolibc support.

- **Tier**: `T1` (`_lib/toolchains/riscv-none-elf-gcc/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `riscv64-unknown-elf-gcc`, `riscv-none-elf-gcc`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/riscv-none-elf-gcc/<version>)
./libscript.sh ls-remote riscv-none-elf-gcc
./libscript.sh install riscv-none-elf-gcc latest
./libscript.sh use riscv-none-elf-gcc latest
./libscript.sh which riscv-none-elf-gcc
./_lib/toolchains/riscv-none-elf-gcc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote riscv-none-elf-gcc
.\libscript.cmd install riscv-none-elf-gcc latest
.\libscript.cmd use riscv-none-elf-gcc latest
.\libscript.cmd which riscv-none-elf-gcc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/riscv-none-elf-gcc/<version>` (default
  `~/.libscript/riscv-none-elf-gcc/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `RISCV_NONE_ELF_GCC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                            | Description                                                                                                                                                 | Default  | Aliases/Examples        |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`          | Target root filesystem staging path when provisioning chroots or OS images.                                                                                 | `none`   | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`             | Target CPU architecture when cross-compiling or building OS images.                                                                                         | `none`   |                         |
| `LIBSCRIPT_TARGET_LIBC`             | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                   | `none`   |                         |
| `LIBSCRIPT_TARGET_OS`               | Target operating system identifier when provisioning or cross-compiling.                                                                                    | `none`   |                         |
| `LIBSCRIPT_HOST_ROOT`               | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                   | `none`   |                         |
| `LIBSCRIPT_STAGE`                   | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                               | `none`   |                         |
| `LIBSCRIPT_IMAGE_BUILD`             | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                         | `0`      |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`      | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                          | `0`      |                         |
| `LIBSCRIPT_ALLOW_STUB`              | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                     | `0`      |                         |
| `LIBSCRIPT_VM_WORKER`               | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                   | `none`   |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK`     | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                          | `none`   |                         |
| `LIBSCRIPT_RELEASEVER`              | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                        | `9`      |                         |
| `LIBSCRIPT_SYSTEMD_DIR`             | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                           | `none`   |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`         | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                         | `none`   |                         |
| `LIBSCRIPT_ETC_DIR`                 | Override root configuration directory for system service config files (defaults to /etc).                                                                   | `none`   |                         |
| `LIBSCRIPT_INITD_DIR`               | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                | `none`   |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`         | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                      | `none`   |                         |
| `LIBSCRIPT_RUN_DIR`                 | Override runtime PID/socket directory (defaults to /var/run).                                                                                               | `none`   |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`           | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                      | `none`   |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`           | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                           | `none`   |                         |
| `LIBSCRIPT_HOME_BASE`               | Base parent directory for user home directories (defaults to /home).                                                                                        | `none`   |                         |
| `LIBSCRIPT_ROOT_HOME`               | Root user home directory override (defaults to /root).                                                                                                      | `none`   |                         |
| `RISCV_NONE_ELF_GCC_INSTALL_METHOD` | How to install riscv-none-elf-gcc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                         |
| `RISCV_NONE_ELF_GCC_VERSION`        | Specific version of riscv-none-elf-gcc to install.                                                                                                          | `13.2.0` | latest, lts             |
| `RISCV_NONE_ELF_GCC_DOWNLOAD_URL`   | Override URL for downloading riscv-none-elf-gcc binary or archive artifacts.                                                                                | `none`   |                         |
| `RISCV_NONE_ELF_GCC_RELEASES_URL`   | Override URL for querying riscv-none-elf-gcc available remote releases.                                                                                     | `none`   |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
