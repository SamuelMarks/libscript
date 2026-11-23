# Python Runtime (`_lib/languages/python/`)

## Overview

A versatile programming language that lets you work quickly and integrate systems more effectively.

- **Tier**: `T1` (`_lib/languages/python/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `runtime`, `python`, `pip`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/python/<version>)
./libscript.sh ls-remote python
./libscript.sh install python latest
./libscript.sh use python latest
./libscript.sh which python
./_lib/languages/python/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote python
.\libscript.cmd install python latest
.\libscript.cmd use python latest
.\libscript.cmd which python
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/python/<version>`
  (default `~/.libscript/python/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PYTHON_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                                                                                                                         | Default            | Aliases/Examples |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIBSCRIPT_BUILD_TOOLCHAIN`     | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default`          |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`       | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`             |                  |
| `LIBSCRIPT_BUILD_CFLAGS`        | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`       | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`             |                  |
| `LIBSCRIPT_SOURCE_WORKDIR`      | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`             |                  |
| `LIBSCRIPT_HW_CORES`            | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_HW_MEM_MB`           | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`             |                  |
| `LIBSCRIPT_HW_NVME`             | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`             |                  |
| `LIBSCRIPT_HW_SIMD`             | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`             |                  |
| `PYTHON_VERSION`                | Version of Python demanded. Can be a specific numeric version number or an alias                                                                                                                                                                                    | `3.11`             | latest, cpython  |
| `PYTHON_VENV`                   | Path to a Python virtualenv (will create if nonexistent)                                                                                                                                                                                                            | `none`             |                  |
| `PYTHON_CUSTOM_EXECUTABLE_PATH` | Path to existing host python3.exe executable. If specified, skips downloading or bootstrapping a new Python runtime.                                                                                                                                                | `none`             |                  |
| `PYTHON_USE_SYSTEM`             | Reuse host or existing Python runtime located at PYTHON_CUSTOM_EXECUTABLE_PATH rather than installing bundled Python.                                                                                                                                               | `none`             |                  |
| `PYTHON_INSTALL_METHOD`         | Installation strategy for python: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager.                                                                                                            | `libscript_native` |                  |
| `PIP_FIND_LINKS`                | Directory or URL containing pre-downloaded Python wheels for offline installation.                                                                                                                                                                                  | `none`             |                  |
| `PIP_NO_INDEX`                  | When set to 1 or true, pip completely disables querying remote PyPI indexes.                                                                                                                                                                                        | `0`                |                  |
| `PIP_WHEEL_DIR`                 | Directory location of pre-downloaded .whl packages for offline pip installs.                                                                                                                                                                                        | `none`             |                  |
| `PYTHON_DOWNLOAD_URL`           | Override URL for downloading python binary or archive artifacts.                                                                                                                                                                                                    | `none`             |                  |
| `PYTHON_RELEASES_URL`           | Override URL for querying python available remote releases.                                                                                                                                                                                                         | `none`             |                  |
| `LIBSCRIPT_FORCE_PYTHONHOME`    | When set to 1, exports PYTHONHOME to the base LibScript Python installation directory if no virtualenv is active.                                                                                                                                                   | `0`                |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
