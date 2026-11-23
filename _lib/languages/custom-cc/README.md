# Custom C Compiler (`custom-cc`)

Standalone T1 LibScript recipe for registering, building, wrapping, and testing a custom C compiler
(`custom-cc`).

## Usage

```sh
# Register a local custom C compiler binary
CUSTOM_CC_BIN=/path/to/mycc ./libscript.sh install custom-cc latest

# Build custom-cc from source using the default host toolchain
./libscript.sh install custom-cc latest --from-source --toolchain=default

# Run C89/C99 conformance smoke tests
./libscript.sh test custom-cc
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                                                                                                                                                         | Default        | Aliases/Examples |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------------- |
| `LIBSCRIPT_BUILD_TOOLCHAIN`   | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default`      |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`     | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`         |                  |
| `LIBSCRIPT_BUILD_CFLAGS`      | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`         |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`     | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`         |                  |
| `LIBSCRIPT_SOURCE_WORKDIR`    | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`         |                  |
| `LIBSCRIPT_HW_CORES`          | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`         |                  |
| `LIBSCRIPT_HW_MEM_MB`         | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`         |                  |
| `LIBSCRIPT_HW_NVME`           | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`         |                  |
| `LIBSCRIPT_HW_SIMD`           | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`         |                  |
| `CUSTOM_CC_VERSION`           | Version identifier for the custom C compiler.                                                                                                                                                                                                                       | `latest`       | latest, stable   |
| `CUSTOM_CC_INSTALL_METHOD`    | Installation strategy for custom-cc ('local_binary' registers an existing binary, 'from-source' compiles custom-cc from source, 'libscript_native' downloads an archive, 'pkg_mgr' uses a package manager, 'wrapper' creates a self-test telemetry wrapper).        | `local_binary` |                  |
| `CUSTOM_CC_PKG_MGR`           | Specific package manager if installing custom-cc from a custom tap or repository.                                                                                                                                                                                   | `none`         |                  |
| `CUSTOM_CC_BUILD_TOOLCHAIN`   | Host C toolchain used to compile custom-cc itself when CUSTOM_CC_INSTALL_METHOD='from-source' (e.g., 'default', 'gcc', 'clang', 'tcc', or self-hosting 'custom-cc').                                                                                                | `default`      |                  |
| `CUSTOM_CC_BIN`               | Filesystem path to a prebuilt custom C compiler binary.                                                                                                                                                                                                             | `none`         |                  |
| `CUSTOM_CC_DOWNLOAD_URL`      | URL for downloading a custom C compiler source or binary archive.                                                                                                                                                                                                   | `none`         |                  |
| `CUSTOM_CC_GIT_URL`           | Git repository URL for building custom-cc from source.                                                                                                                                                                                                              | `none`         |                  |
| `CUSTOM_CC_BUILD_CMD`         | Command used to build custom-cc from source.                                                                                                                                                                                                                        | `make`         |                  |
| `CUSTOM_CC_EXTRA_CFLAGS`      | Additional CFLAGS appended by the custom-cc wrapper.                                                                                                                                                                                                                | ``             |                  |
| `CUSTOM_CC_STRIP_GNU_FLAGS`   | Whether cc_wrapper should strip GCC/Clang-specific warning and hardening flags unsupported by minimal C compilers.                                                                                                                                                  | `true`         |                  |
| `CUSTOM_CC_FALLBACK_CC`       | Optional fallback C compiler binary invoked when custom-cc encounters unsupported GNU extensions or when running in CI wrapper mode.                                                                                                                                | ``             |                  |
| `CUSTOM_CC_FALLBACK_ON_ERROR` | Whether cc_wrapper should retry failed compilation units with CUSTOM_CC_FALLBACK_CC and record fallback telemetry.                                                                                                                                                  | `none`         |                  |
| `CUSTOM_CC_LOG_FILE`          | Filesystem path to the JSONL telemetry log recording custom-cc compiler invocations, fallback events, and elapsed durations.                                                                                                                                        | `none`         |                  |
| `CUSTOM_CC_REAL_BIN`          | Path to the underlying custom C compiler executable invoked by the custom-cc wrapper before any fallback.                                                                                                                                                           | `none`         |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
