# LLVM Clang (`clang`)

Standalone T1 LibScript recipe for the LLVM Clang C/C++ Compiler (`clang`).

## Installation Modes

1. **Mode 1 — Specific Package Manager**:
   ```sh
   ./libscript.sh install clang latest --pkg-mgr=apt-get
   ./libscript.sh install clang latest --pkg-mgr=brew
   ```
2. **Mode 2 — Build from Source (Default Toolchain)**:
   ```sh
   ./libscript.sh install clang 18.1.8 --from-source --toolchain=default
   ```
3. **Mode 3 — Build from Source (Custom Toolchain)**:
   ```sh
   ./libscript.sh install clang 18.1.8 --from-source --toolchain=gcc
   ```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                   | Default   | Aliases/Examples |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------- |
| `CLANG_VERSION`         | Version of LLVM Clang to install or build.                                                                                                                    | `latest`  | latest, stable   |
| `CLANG_INSTALL_METHOD`  | Installation strategy for Clang ('system' via package manager, 'from-source' compiled from source, 'libscript_native' prebuilt archive, or version managers). | `system`  |                  |
| `CLANG_PKG_MGR`         | Specific package manager to use when installing Clang (e.g., apt-get, apk, dnf, brew, pacman, winget, choco, scoop, nix, spack).                              | `none`    |                  |
| `CLANG_BUILD_TOOLCHAIN` | Bootstrap C toolchain used when CLANG_INSTALL_METHOD='from-source'.                                                                                           | `default` |                  |
| `CLANG_DOWNLOAD_URL`    | Explicit source or binary archive URL for LLVM Clang.                                                                                                         | `none`    |                  |
| `CLANG_USE_LLD`         | Whether to configure LLD as the default linker when using Clang.                                                                                              | `true`    |                  |
| `CLANG_CFLAGS`          | Default optimization and code generation flags exported when using Clang.                                                                                     | `-O2`     |                  |
| `CLANG_BUILD_TARGET`    | Specific LLVM/Clang target to build when benchmarking ('llvm-core' for opt/llc/llvm-core, 'clang' for C/C++ frontend, or 'clang++' for full C++ toolchain).   | `none`    |                  |
| `CLANG_MATCHED`         | Exact clang executable matching the LLVM version linked into cpfe.                                                                                            | `none`    |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
