# Linux

**Tier**: `T2` (`_lib/kernel/linux/`) | **Capabilities**: `sysroot-package`, `kernel-image`

Linux component for LibScript systems.

## Usage

```sh
./libscript.sh install linux
LINUX_BUILD_TOOLCHAIN=custom-cc ./_lib/kernel/linux/setup.sh compile
./_lib/kernel/linux/compare_compilers.sh
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                                                                                                                         | Default                 | Aliases/Examples                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ---------------------------------- |
| `LIBSCRIPT_BUILD_TOOLCHAIN`      | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default`               |                                    |
| `LIBSCRIPT_CUSTOM_CC_BIN`        | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`                  |                                    |
| `LIBSCRIPT_BUILD_CFLAGS`         | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`                  |                                    |
| `LIBSCRIPT_BUILD_LDFLAGS`        | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`                  |                                    |
| `LIBSCRIPT_SOURCE_WORKDIR`       | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`                  |                                    |
| `LIBSCRIPT_HW_CORES`             | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`                  |                                    |
| `LIBSCRIPT_HW_MEM_MB`            | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`                  |                                    |
| `LIBSCRIPT_HW_NVME`              | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`                  |                                    |
| `LIBSCRIPT_HW_SIMD`              | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`                  |                                    |
| `LINUX_VERSION`                  | Specific version of the Linux kernel to install or compile (e.g., '6.6.52' or 'latest').                                                                                                                                                                            | `6.6.52`                |                                    |
| `LINUX_INSTALL_METHOD`           | How to provision the Linux kernel ('from-source' compiles via Kbuild, 'system' installs via OS package manager, 'libscript_native' stages prebuilt artifacts).                                                                                                      | `from-source`           |                                    |
| `LINUX_PKG_MGR`                  | Specific package manager when LINUX_INSTALL_METHOD='system'.                                                                                                                                                                                                        | `none`                  |                                    |
| `LINUX_BUILD_TOOLCHAIN`          | Toolchain used to compile the Linux kernel ('default', 'gcc', 'clang', 'tcc', 'custom-cc', or compiler binary path).                                                                                                                                                | `default`               |                                    |
| `LINUX_COMPILER`                 | Alias for LINUX_BUILD_TOOLCHAIN specifying the C compiler for Kbuild.                                                                                                                                                                                               | `default`               |                                    |
| `LINUX_HOSTCC`                   | Host C compiler used for Kbuild host utilities (scripts/basic/fixdep, scripts/kconfig/conf).                                                                                                                                                                        | ``                      |                                    |
| `LINUX_KCFLAGS`                  | Extra KCFLAGS passed to the Linux kernel Kbuild invocation.                                                                                                                                                                                                         | `-O2`                   |                                    |
| `LINUX_CONFIG_TARGET`            | Kernel Kconfig target ('tinyconfig', 'defconfig', 'x86_64_defconfig', 'allnoconfig', 'virtconfig', or 'custom').                                                                                                                                                    | `tinyconfig`            |                                    |
| `LINUX_SOURCE_URL`               | Optional explicit download URL for the Linux kernel source tarball.                                                                                                                                                                                                 | `none`                  |                                    |
| `LINUX_SHA256`                   | Optional SHA-256 checksum for verifying the downloaded Linux kernel source archive.                                                                                                                                                                                 | `none`                  |                                    |
| `LINUX_SYNTHETIC_FALLBACK`       | Whether to compile a freestanding multi-TU kernel ELF harness with the target compiler when full Linux kernel source is not cached locally.                                                                                                                         | `true`                  |                                    |
| `LINUX_COMPARE_COMPILERS`        | Space-separated list of compiler toolchains (e.g., gcc, clang, tcc, edgcpp+gcc, edgcpp+llvm) evaluated in Linux kernel build matrices.                                                                                                                              | `none`                  |                                    |
| `LINUX_SOURCE_DIR`               | Filesystem directory or path configuration for linux (LINUX_SOURCE_DIR).                                                                                                                                                                                            | `none`                  |                                    |
| `LINUX_COMPARE_VERSIONS`         | Space-separated list of Linux kernel versions to evaluate in compare_compilers.sh (e.g., '4.19.322 5.4.284 5.10.226 5.15.167 6.1.112 6.6.52 6.11.2 6.12.1').                                                                                                        | `none`                  |                                    |
| `LINUX_COMPARE_EDGCPP_BACKENDS`  | Space-separated list of edgcpp codegen backends ('llvm_backend gcc_backend') to evaluate when comparing Linux kernel builds.                                                                                                                                        | `none`                  |                                    |
| `LINUX_DEFAULT_SHA256`           | Default SHA-256 checksum for the resolved Linux kernel source tarball.                                                                                                                                                                                              | `none`                  |                                    |
| `LINUX_EXPECT_CLANG_FAIL`        | Whether raw CC=clang Kbuild invocations without LLVM=1 compatibility overrides are expected to fail on GNU C kernel flags and constructs (default '1').                                                                                                             | `none`                  |                                    |
| `LINUX_ALLOW_CLANG_KBUILD`       | Override flag ('1') to allow Clang Kbuild compilation by omitting GCC-only Kbuild flags.                                                                                                                                                                            | `none`                  |                                    |
| `LINUX_COMPARE_DISTROS`          | Space-separated list of Vagrant Linux distributions ('debian-13 rockylinux-10.2 alpine-3.24') to evaluate in the Vagrant kernel compiler matrix.                                                                                                                    | `none`                  |                                    |
| `LINUX_SWEEP_SUBDIRS`            | Space-separated Kbuild subdirectories included in the Experiment 6B compile_commands.json per-TU replay sweep.                                                                                                                                                      | `init/ kernel/ mm/ fs/` |                                    |
| `LINUX_SWEEP_OUT_JSON`           | Output JSON path written by the compile-commands-sweep action recording tus_ok, tus_total, loc, median/max RSS, and failure categories.                                                                                                                             | `none`                  |                                    |
| `LINUX_BUILD_KERNEL_FROM_SOURCE` | Flag (0 or 1) instructing kernel synthesis to compile the Linux kernel from source when no prebuilt kernel exists.                                                                                                                                                  | `0`                     | LIBSCRIPT_BUILD_KERNEL_FROM_SOURCE |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
