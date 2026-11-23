# Tiny C Compiler (`tcc`)

Standalone T1 LibScript recipe for Fabrice Bellard's Tiny C Compiler (`tcc`).

## Installation Modes

1. **Mode 1 — Specific Package Manager**:
   ```sh
   ./libscript.sh install tcc latest --pkg-mgr=apk
   ./libscript.sh install tcc latest --pkg-mgr=apt-get
   ```
2. **Mode 2 — Build from Source (Default Toolchain)**:
   ```sh
   ./libscript.sh install tcc 0.9.27 --from-source --toolchain=default
   ```
3. **Mode 3 — Build from Source (Custom Toolchain)**:
   ```sh
   ./libscript.sh install tcc 0.9.27 --from-source --toolchain=clang
   ```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                                                                                                                                         | Default                         | Aliases/Examples |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | ---------------- |
| `LIBSCRIPT_BUILD_TOOLCHAIN` | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default`                       |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`   | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`                          |                  |
| `LIBSCRIPT_BUILD_CFLAGS`    | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`                          |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`   | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`                          |                  |
| `LIBSCRIPT_SOURCE_WORKDIR`  | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`                          |                  |
| `LIBSCRIPT_HW_CORES`        | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`                          |                  |
| `LIBSCRIPT_HW_MEM_MB`       | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`                          |                  |
| `LIBSCRIPT_HW_NVME`         | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`                          |                  |
| `LIBSCRIPT_HW_SIMD`         | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`                          |                  |
| `LIBSCRIPT_JOBS`            | Explicit positive integer worker count overriding auto-detected CPU concurrency for parallel pre-commit hooks, static audits, and sharded batch tasks (set to 1 for sequential execution).                                                                          | `none`                          |                  |
| `TCC_VERSION`               | Version of Tiny C Compiler (TCC) to install or build.                                                                                                                                                                                                               | `0.9.27`                        | latest, stable   |
| `TCC_INSTALL_METHOD`        | Installation strategy for TCC ('system' via package manager, 'from-source' compiled from source, or 'libscript_native').                                                                                                                                            | `system`                        |                  |
| `TCC_PKG_MGR`               | Specific package manager to use when installing TCC (e.g., apt-get, apk, dnf, brew, pacman, winget, choco, scoop, nix, spack).                                                                                                                                      | `none`                          |                  |
| `TCC_BUILD_TOOLCHAIN`       | Bootstrap C toolchain used when TCC_INSTALL_METHOD='from-source' ('default', 'gcc', 'clang', 'custom-cc').                                                                                                                                                          | `default`                       |                  |
| `TCC_DOWNLOAD_URL`          | Explicit source tarball or archive URL for TCC.                                                                                                                                                                                                                     | `none`                          |                  |
| `TCC_GIT_URL`               | Git repository URL for building TCC from source.                                                                                                                                                                                                                    | `https://repo.or.cz/tinycc.git` |                  |
| `TCC_CFLAGS`                | Default compiler flags exported when using TCC.                                                                                                                                                                                                                     | `-O2`                           |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
