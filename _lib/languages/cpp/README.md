# C++ Toolchain (`_lib/languages/cpp/`)

## Overview

Standard C++ compiler and toolchain (G++/Clang++).

- **Tier**: `T1` (`_lib/languages/cpp/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `compiler`, `c++`, `cpp`, `g++`, `clang++`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/cpp/<version>)
./libscript.sh ls-remote cpp
./libscript.sh install cpp latest
./libscript.sh use cpp latest
./libscript.sh which cpp
./_lib/languages/cpp/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote cpp
.\libscript.cmd install cpp latest
.\libscript.cmd use cpp latest
.\libscript.cmd which cpp
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/cpp/<version>`
  (default `~/.libscript/cpp/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CPP_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                           | Default   | Aliases/Examples |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------- |
| `CPP_INSTALL_METHOD`  | Installation strategy for cpp: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system`  |                  |
| `CPP_VERSION`         | Version of C++ Toolchain to install                                                                                                                   | `latest`  |                  |
| `CXX_BACKEND`         | Active C++ compiler backend routed by cpp ('default', 'gcc', 'clang', 'edgcpp', 'custom-cc').                                                         | `default` |                  |
| `CPP_BUILD_TOOLCHAIN` | Bootstrap C++ toolchain used when building C++ toolchain from source.                                                                                 | `default` |                  |
| `CPP_DOWNLOAD_URL`    | Override URL for downloading cpp binary or archive artifacts.                                                                                         | `none`    |                  |
| `CPP_RELEASES_URL`    | Override URL for querying cpp available remote releases.                                                                                              | `none`    |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
