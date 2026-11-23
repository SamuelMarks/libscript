# C Toolchain (`_lib/languages/c/`)

## Overview

Standard C compiler and toolchain (GCC/Clang).

- **Tier**: `T1` (`_lib/languages/c/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `compiler`, `c`, `gcc`, `clang`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/c/<version>)
./libscript.sh ls-remote c
./libscript.sh install c latest
./libscript.sh use c latest
./libscript.sh which c
./_lib/languages/c/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote c
.\libscript.cmd install c latest
.\libscript.cmd use c latest
.\libscript.cmd which c
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/c/<version>` (default
  `~/.libscript/c/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without
  polluting system paths.
- **Override Strategy**: Control installation via `C_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                                                                       | Default   | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------- |
| `C_INSTALL_METHOD`  | Installation strategy for c: 'libscript_native' installs into isolated versioned directories, 'from-source' compiles from source archives, and 'system' delegates to the host OS package manager. | `system`  |                  |
| `C_VERSION`         | Version of C Toolchain to install                                                                                                                                                                 | `latest`  |                  |
| `CC_BACKEND`        | Active C compiler backend routed by c ('default', 'gcc', 'clang', 'tcc', 'edgcpp', 'custom-cc').                                                                                                  | `default` |                  |
| `C_PKG_MGR`         | Explicit package manager override for C toolchain installation.                                                                                                                                   | `none`    |                  |
| `C_BUILD_TOOLCHAIN` | Bootstrap C toolchain used when building C toolchain from source.                                                                                                                                 | `default` |                  |
| `C_DOWNLOAD_URL`    | Override URL for downloading c binary or archive artifacts.                                                                                                                                       | `none`    |                  |
| `C_RELEASES_URL`    | Override URL for querying c available remote releases.                                                                                                                                            | `none`    |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
