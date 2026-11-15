# GNU Compiler Collection (`gcc`)

Standalone Tier 1 LibScript recipe for the GNU C/C++ Compiler (`gcc`).

## Installation Modes

1. **Mode 1 — Specific Package Manager**:
   ```sh
   ./libscript.sh install gcc latest --pkg-mgr=apt-get
   ./libscript.sh install gcc latest --pkg-mgr=brew
   ```
2. **Mode 2 — Build from Source (Default Toolchain)**:
   ```sh
   ./libscript.sh install gcc 14.2.0 --from-source --toolchain=default
   ```
3. **Mode 3 — Build from Source (Custom Toolchain)**:
   ```sh
   ./libscript.sh install gcc 14.2.0 --from-source --toolchain=clang
   ```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                             | Default   | Aliases/Examples |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------- |
| `GCC_VERSION`          | Version of GCC to install or build.                                                                                                                                     | `latest`  | latest, stable   |
| `GCC_INSTALL_METHOD`   | Installation strategy for GCC ('system' via OS/selected package manager, 'from-source' compiled from source, 'libscript_native' prebuilt archive, or version managers). | `system`  |                  |
| `GCC_PKG_MGR`          | Specific package manager to use when installing GCC (e.g., apt-get, apk, dnf, brew, pacman, winget, choco, scoop, nix, spack).                                          | `none`    |                  |
| `GCC_BUILD_TOOLCHAIN`  | Bootstrap C toolchain used when GCC_INSTALL_METHOD='from-source'.                                                                                                       | `default` |                  |
| `GCC_DOWNLOAD_URL`     | Optional explicit download URL for GCC source or prebuilt archive.                                                                                                      | `none`    |                  |
| `GCC_CFLAGS`           | Default compiler flags exported by the GCC environment.                                                                                                                 | `-O2`     |                  |
| `GCC_ENABLE_LANGUAGES` | Comma-separated list of languages to enable when building GCC from source ('c' for gcc-core or 'c,c++' for g++).                                                        | `c,c++`   |                  |
| `GCC_BUILD_TARGET`     | Specific GCC subsystem target to build when benchmarking ('gcc-core' for C front-end or 'g++' for C++ front-end).                                                       | `none`    |                  |
| `GCC_PREFIX`           | Installation prefix of the matched GCC and libgccjit installation.                                                                                                      | `none`    |                  |
| `GCC_MATCHED`          | Exact gcc executable matching the version of EDG_LIBGCCJIT_PATH.                                                                                                        | `none`    |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
