# Upstream Google libtpu Reference Wheel & Shared Objects (`_lib/runtimes/libtpu/`)

## Overview

Isolated version manager and SHA-256 verified artifact cache for upstream PyPI libtpu wheels
(libtpu.so and sdk.so).

- **Tier**: `T1` (`_lib/runtimes/libtpu/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/libtpu/<version>)
./libscript.sh ls-remote libtpu
./libscript.sh install libtpu latest
./libscript.sh use libtpu latest
./libscript.sh which libtpu
./_lib/runtimes/libtpu/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote libtpu
.\libscript.cmd install libtpu latest
.\libscript.cmd use libtpu latest
.\libscript.cmd which libtpu
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/libtpu/<version>`
  (default `~/.libscript/libtpu/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LIBTPU_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                     | Default            | Aliases/Examples |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIBTPU_INSTALL_METHOD`            | How to install libtpu. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LIBTPU_VERSION`                   | Specific version of libtpu to install.                                                                                                          | `0.0.52`           | latest, lts      |
| `LIBTPU_DOWNLOAD_URL`              | Override URL for downloading libtpu binary or archive artifacts.                                                                                | `none`             |                  |
| `LIBTPU_RELEASES_URL`              | Override URL for querying libtpu available remote releases.                                                                                     | `none`             |                  |
| `LIBTPU_WHEEL_ARCH`                | Wheel architecture(s) to fetch and extract ('x86_64', 'aarch64', or 'both').                                                                    | `both`             |                  |
| `LIBTPU_SO_PATH`                   | Explicit override path to an extracted upstream libtpu.so shared object.                                                                        | `none`             |                  |
| `LIBTPU_SDK_SO_PATH`               | Explicit override path to an extracted upstream sdk.so / sdk.abi3.so shared object.                                                             | `none`             |                  |
| `LIBTPU_REFERENCE_DIR`             | Resolved directory containing extracted upstream libtpu reference wheels and shared objects.                                                    | `none`             |                  |
| `LIBTPU_REFERENCE_SO`              | Resolved path to the active host-matching upstream libtpu.so artifact.                                                                          | `none`             |                  |
| `LIBTPU_REFERENCE_SDK_SO`          | Resolved path to the active host-matching upstream sdk.so artifact.                                                                             | `none`             |                  |
| `LIBTPU_ACTIVATE_TPU_LIBRARY_PATH` | Flag (0 or 1) controlling whether env.sh/env.cmd exports TPU_LIBRARY_PATH pointing at upstream libtpu.so.                                       | `0`                |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
