# Lua (`_lib/languages/lua/`)

## Overview

Lightweight, embeddable, fast scripting language interpreter and bytecode compiler.

- **Tier**: `T1` (`_lib/languages/lua/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `lua`, `luac`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/lua/<version>)
./libscript.sh ls-remote lua
./libscript.sh install lua latest
./libscript.sh use lua latest
./libscript.sh which lua
./_lib/languages/lua/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote lua
.\libscript.cmd install lua latest
.\libscript.cmd use lua latest
.\libscript.cmd which lua
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/lua/<version>`
  (default `~/.libscript/lua/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LUA_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                                                                                                                         | Default   | Aliases/Examples        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                                                                                                                         | `none`    | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                                                                                                                                 | `none`    |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                                                                                                                           | `none`    |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                                                                                                                            | `none`    |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                                                                                                                           | `none`    |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                                                                                                                       | `none`    |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                                                                                                                 | `0`       |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                                                                                                                  | `0`       |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                                                                                                                             | `0`       |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                                                                                                                           | `none`    |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                                                                                                                  | `none`    |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                                                                                                                | `9`       |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                                                                                                                   | `none`    |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                                                                                                                 | `none`    |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                                                                                                                           | `none`    |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                                                                                                                        | `none`    |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                                                                                                              | `none`    |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                                                                                                                       | `none`    |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                                                                                                              | `none`    |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                                                                                                                   | `none`    |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                                                                                                                                | `none`    |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                                                                                                                              | `none`    |                         |
| `LIBSCRIPT_BUILD_TOOLCHAIN`     | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default` |                         |
| `LIBSCRIPT_CUSTOM_CC_BIN`       | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`    |                         |
| `LIBSCRIPT_BUILD_CFLAGS`        | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`    |                         |
| `LIBSCRIPT_BUILD_LDFLAGS`       | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`    |                         |
| `LIBSCRIPT_SOURCE_WORKDIR`      | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`    |                         |
| `LIBSCRIPT_HW_CORES`            | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`    |                         |
| `LIBSCRIPT_HW_MEM_MB`           | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`    |                         |
| `LIBSCRIPT_HW_NVME`             | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`    |                         |
| `LIBSCRIPT_HW_SIMD`             | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`    |                         |
| `LUA_INSTALL_METHOD`            | How to install lua. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source.                                                                                                                        | `system`  |                         |
| `LUA_VERSION`                   | Specific version of lua to install.                                                                                                                                                                                                                                 | `latest`  | latest, lts             |
| `LUA_DOWNLOAD_URL`              | Override URL for downloading lua binary or archive artifacts.                                                                                                                                                                                                       | `none`    |                         |
| `LUA_RELEASES_URL`              | Override URL for querying lua available remote releases.                                                                                                                                                                                                            | `none`    |                         |
| `LUA_RUN_TESTS`                 | Whether to fetch and execute the official upstream lua-X.Y.Z-tests suite (all.lua) after building Lua from source.                                                                                                                                                  | `none`    |                         |
| `LUA_TESTS_URL`                 | Optional explicit URL for the official Lua test suite archive (defaults to https://www.lua.org/tests/lua-{VERSION}-tests.tar.gz).                                                                                                                                   | `none`    |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
