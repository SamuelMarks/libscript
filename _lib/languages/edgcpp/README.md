# EDG C/C++ Compiler Frontend (`edgcpp`)

Standalone version manager, multi-flavor binary installer, source builder, and `CC`/`CXX` compiler
driver wrapper for the **Edison Design Group (EDG) C/C++ Front End (`edgcpp` v7.0.1)**
([`SamuelMarks/edgcpp-compiler`](https://github.com/SamuelMarks/edgcpp-compiler/releases/tag/v7.0.1)).

## Overview

`_lib/languages/edgcpp/` manages the installation and lifecycle of `edgcpp` (`v7.0.1`) across Linux
(`x86_64`, `aarch64`), macOS (`aarch64`), and Windows (`x86_64`, `arm64`). It provisions the EDG
C/C++ front-end binaries (`cpfe`, `cpfe-cp`, `cdisp`, `mk_errinfo`, `edg_decode`), standard library
headers (`include_c99/`, `include_c++/`), and drop-in compiler driver shims (`edgcpp`, `edg-cc`,
`edg-c++`) compatible with `make`, `Kbuild`, `autotools`, and `CMake`.

## Usage

```sh
# Install edgcpp v7.0.1 (default flavor: edgcpp+llvm+gcc)
./libscript.sh install edgcpp 7.0.1

# List installed and remote versions
./libscript.sh ls edgcpp
./libscript.sh ls-remote edgcpp

# Run C11 and C++17 conformance tests
./libscript.sh test edgcpp

# Build components from source using edgcpp
./libscript.sh install sqlite 3.46.1 --from-source --toolchain=edgcpp
./libscript.sh install linux 6.6.52 --from-source --toolchain=edgcpp
```

## Configuration Variables

| Variable                | Description                                                                                                      | Default                                         |
| :---------------------- | :--------------------------------------------------------------------------------------------------------------- | :---------------------------------------------- |
| `EDGCPP_VERSION`        | Version of `edgcpp` to install (`7.0.1`, `latest`, `stable`).                                                    | `7.0.1`                                         |
| `EDGCPP_FLAVOR`         | Release backend flavor (`edgcpp+llvm+gcc`, `edgcpp+llvm`, `edgcpp+gcc`).                                         | `edgcpp+llvm+gcc`                               |
| `EDGCPP_INSTALL_METHOD` | Installation mode (`libscript_native`, `from-source`, `local_binary`, `pkg_mgr`, `system`).                      | `libscript_native`                              |
| `EDGCPP_BACKEND_CC`     | Underlying C compiler/assembler/linker used after front-end processing.                                          | `cc`                                            |
| `EDGCPP_BACKEND_CXX`    | Underlying C++ compiler/linker used after front-end processing.                                                  | `c++`                                           |
| `EDGCPP_EMULATION_MODE` | EDG dialect compatibility mode (`auto`, `gcc`, `clang`, `msvc`, `c89`, `c99`, `c11`, `c++17`, `c++20`, `c++23`). | `auto`                                          |
| `EDGCPP_LOG_FILE`       | Path to JSONL compilation telemetry log.                                                                         | `${LIBSCRIPT_HOME}/edgcpp/compile_events.jsonl` |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                                                                                                                         | Default                                              | Aliases/Examples |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | ---------------- |
| `LIBSCRIPT_BUILD_TOOLCHAIN`     | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default`                                            |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`       | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`                                               |                  |
| `LIBSCRIPT_BUILD_CFLAGS`        | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`                                               |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`       | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`                                               |                  |
| `LIBSCRIPT_SOURCE_WORKDIR`      | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`                                               |                  |
| `LIBSCRIPT_HW_CORES`            | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`                                               |                  |
| `LIBSCRIPT_HW_MEM_MB`           | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`                                               |                  |
| `LIBSCRIPT_HW_NVME`             | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`                                               |                  |
| `LIBSCRIPT_HW_SIMD`             | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`                                               |                  |
| `EDGCPP_VERSION`                | Specific version or semantic alias of edgcpp to install (e.g., '7.0.1', 'v7.0.1', '7.0', 'latest', or 'stable').                                                                                                                                                    | `7.0.1`                                              |                  |
| `EDGCPP_FLAVOR`                 | Release backend flavor of edgcpp to install ('edgcpp+llvm+gcc' for combined LLVM and GCC/C-generating backend support, 'edgcpp+llvm' for LLVM backend, or 'edgcpp+gcc' for GCC/C-generating backend).                                                               | `edgcpp+llvm+gcc`                                    |                  |
| `EDGCPP_INSTALL_METHOD`         | Provisioning strategy for edgcpp ('libscript_native' downloads official GitHub release archives, 'from-source' compiles from source, 'local_binary' registers an existing cpfe binary, or 'pkg_mgr'/'system').                                                      | `libscript_native`                                   |                  |
| `EDGCPP_PKG_MGR`                | Explicit package manager override for Mode 1 installation.                                                                                                                                                                                                          | `none`                                               |                  |
| `EDGCPP_BUILD_TOOLCHAIN`        | Bootstrap C/C++ compiler toolchain used when compiling edgcpp from source ('default', 'gcc', 'clang', 'tcc', or 'custom-cc').                                                                                                                                       | `default`                                            |                  |
| `EDGCPP_DOWNLOAD_URL`           | Optional override URL for downloading an edgcpp binary or source archive.                                                                                                                                                                                           | `none`                                               |                  |
| `EDGCPP_GIT_URL`                | Git repository URL used when building edgcpp from source via git.                                                                                                                                                                                                   | `https://github.com/SamuelMarks/edgcpp-compiler.git` |                  |
| `EDGCPP_BIN`                    | Filesystem path to an existing cpfe or edgcpp driver executable.                                                                                                                                                                                                    | `none`                                               |                  |
| `EDGCPP_BACKEND_CC`             | Underlying C compiler/assembler/linker invoked after EDG front-end processing ('gcc', 'clang', 'cl', or 'cc').                                                                                                                                                      | `cc`                                                 |                  |
| `EDGCPP_BACKEND_CXX`            | Underlying C++ compiler/linker invoked after EDG C++ front-end processing ('g++', 'clang++', 'cl', or 'c++').                                                                                                                                                       | `c++`                                                |                  |
| `EDGCPP_EMULATION_MODE`         | EDG front-end language/dialect emulation mode ('auto', 'gcc', 'clang', 'msvc', 'c89', 'c99', 'c11', 'c++17', 'c++20', 'c++23').                                                                                                                                     | `auto`                                               |                  |
| `EDGCPP_EXTRA_CFLAGS`           | Additional C compiler flags appended by the edgcpp driver wrapper.                                                                                                                                                                                                  | ``                                                   |                  |
| `EDGCPP_EXTRA_CXXFLAGS`         | Additional C++ compiler flags appended by the edg-c++ driver wrapper.                                                                                                                                                                                               | ``                                                   |                  |
| `EDGCPP_STRIP_GNU_FLAGS`        | Whether the edgcpp wrapper strips backend-only GNU/Clang machine and optimizer flags before passing arguments to cpfe.                                                                                                                                              | `true`                                               |                  |
| `EDGCPP_FALLBACK_ON_ERROR`      | Whether edgcpp_wrapper should fallback to EDGCPP_BACKEND_CC when a translation unit uses unsupported target-specific extensions while recording telemetry.                                                                                                          | `none`                                               |                  |
| `EDGCPP_LOG_FILE`               | Path to the JSONL compilation telemetry log file written by edgcpp_wrapper.                                                                                                                                                                                         | `none`                                               |                  |
| `EDGCPP_ACTIVE_CODEGEN_BACKEND` | Configuration variable EDGCPP_ACTIVE_CODEGEN_BACKEND for edgcpp.                                                                                                                                                                                                    | `none`                                               |                  |
| `EDGCPP_BACKEND_MODE`           | Configuration variable EDGCPP_BACKEND_MODE for edgcpp.                                                                                                                                                                                                              | `none`                                               |                  |
| `EDGCPP_BUILD_FROM_GIT`         | Configuration variable EDGCPP_BUILD_FROM_GIT for edgcpp.                                                                                                                                                                                                            | `none`                                               |                  |
| `EDGCPP_DOWNLOAD_DIR`           | Filesystem directory or path configuration for edgcpp (EDGCPP_DOWNLOAD_DIR).                                                                                                                                                                                        | `none`                                               |                  |
| `EDGCPP_DRIVER_LANG`            | Configuration variable EDGCPP_DRIVER_LANG for edgcpp.                                                                                                                                                                                                               | `none`                                               |                  |
| `EDGCPP_FORCE_LINUX_LLVM_OBJ`   | Configuration variable EDGCPP_FORCE_LINUX_LLVM_OBJ for edgcpp.                                                                                                                                                                                                      | `none`                                               |                  |
| `EDGCPP_HOME`                   | Filesystem directory or path configuration for edgcpp (EDGCPP_HOME).                                                                                                                                                                                                | `none`                                               |                  |
| `EDGCPP_STRICT_BACKEND`         | Configuration variable EDGCPP_STRICT_BACKEND for edgcpp.                                                                                                                                                                                                            | `none`                                               |                  |
| `EDGCPP_USE_NATIVE_CODEGEN`     | Configuration variable EDGCPP_USE_NATIVE_CODEGEN for edgcpp.                                                                                                                                                                                                        | `none`                                               |                  |
| `EDGCPP_CHECK_LATEST`           | Whether to query the GitHub Releases API dynamically for the latest SamuelMarks/edgcpp-compiler release tag when EDGCPP_VERSION is 'latest'.                                                                                                                        | `none`                                               |                  |
| `EDGCPP_ASSET_NAME`             | Resolved GitHub release archive filename for edgcpp.                                                                                                                                                                                                                | `none`                                               |                  |
| `EDGCPP_ASSET_SHA256`           | Resolved SHA-256 digest for the edgcpp release archive.                                                                                                                                                                                                             | `none`                                               |                  |
| `EDGCPP_INSTALLED_FLAVOR`       | Flavor recorded in edgcpp.env for the installed edgcpp prefix ('edgcpp+gcc', 'edgcpp+llvm', or 'edgcpp+llvm+gcc').                                                                                                                                                  | `none`                                               |                  |
| `EDGCPP_ACTIVE_FLAVOR`          | Active release flavor resolved by edgcpp_wrapper at runtime.                                                                                                                                                                                                        | `none`                                               |                  |
| `EDGCPP_FAILURE_LOG`            | Path to the detailed diagnostic failure log written by edgcpp_wrapper when cpfe front-end or native backend compilation fails.                                                                                                                                      | `none`                                               |                  |
| `EDGCPP_REPRO_DIR`              | Directory where edgcpp_wrapper writes self-contained preprocessed (.i) translation units and standalone repro.sh / repro.cmd scripts on compilation failure.                                                                                                        | `none`                                               |                  |
| `EDGCPP_VERBOSE_DIAGNOSTICS`    | Whether to print full cpfe failure forensic blocks to stderr even when EDGCPP_STRICT_BACKEND is not enabled.                                                                                                                                                        | `none`                                               |                  |
| `EDGCPP_RESOLVED_BACKEND`       | Resolved host C/C++ compiler/linker executable used by edgcpp_wrapper.                                                                                                                                                                                              | `none`                                               |                  |
| `EDGCPP_RESOLVED_CPFE_CP`       | Resolved path to the cpfe-cp C++-generating backend executable.                                                                                                                                                                                                     | `none`                                               |                  |
| `EDGCPP_RESOLVED_CPFE`          | Resolved path to the primary cpfe front-end and multi-backend executable.                                                                                                                                                                                           | `none`                                               |                  |
| `EDGCPP_PHASE_TIMING`           | Whether to record detailed 4-phase compilation latency breakdown (fe_ms, lower_il_ms, be_ms, codegen_ms) in compile_events.jsonl.                                                                                                                                   | `none`                                               |                  |
| `EDGCPP_TORTURE_SUITE_DIR`      | Optional directory path to an external GCC C torture execution suite when running _lib/languages/edgcpp/torture_suite.sh.                                                                                                                                           | `none`                                               |                  |
| `EDGCPP_BENCH_RUNS`             | Number of compilation benchmark runs per workload/compiler configuration (defaults to 5: 1 cold run + 4 warm runs averaged).                                                                                                                                        | `none`                                               |                  |
| `EDGCPP_GNU_VERSION`            | GNU C/C++ compatibility version passed via --gnu_version=<ver> to cpfe without triggering the --gcc libgccjit backend switch.                                                                                                                                       | `130200`                                             |                  |
| `EDGCPP_SOURCE_DIR`             | Local filesystem checkout path of edgcpp-compiler-multibackend used for Release, 4-mode matrix, coverage, and Bug #4 ablation builds.                                                                                                                               | `none`                                               |                  |
| `EDGCPP_REQUIRE_CLEAN_GIT`      | When set to '1', requires EDGCPP_SOURCE_DIR to be a clean, non-dirty git worktree before building benchmark binaries.                                                                                                                                               | `none`                                               |                  |
| `EDGCPP_BUILD_MODE`             | CMake build profile for edgcpp source builds ('release', 'llvm-cov', 'gcov', 'bug4-legacy', or 'all-modes').                                                                                                                                                        | `none`                                               |                  |
| `EDGCPP_RT_LIB`                 | Filesystem path to libedg.a (containing gcc_be_eh_rt.o) automatically linked for C++ targets under EDG_BACKEND=gcc or EDG_BACKEND=c.                                                                                                                                | `none`                                               |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
