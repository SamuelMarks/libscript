# LLVM (`_lib/toolchains/llvm/`)

## Overview

Modular compiler infrastructure and backend toolchain utilities.

- **Tier**: `T1` (`_lib/toolchains/llvm/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `llvm`, `llvm-config`, `llc`, `opt`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/llvm/<version>)
./libscript.sh ls-remote llvm
./libscript.sh install llvm latest
./libscript.sh use llvm latest
./libscript.sh which llvm
./_lib/toolchains/llvm/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote llvm
.\libscript.cmd install llvm latest
.\libscript.cmd use llvm latest
.\libscript.cmd which llvm
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/llvm/<version>`
  (default `~/.libscript/llvm/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LLVM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `LLVM_INSTALL_METHOD` | How to install llvm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `LLVM_VERSION`        | Specific version of llvm to install.                                                                                                          | `latest` | latest, 19.1.6   |
| `LLVM_DOWNLOAD_URL`   | Override URL for downloading llvm binary or archive artifacts.                                                                                | `none`   |                  |
| `LLVM_RELEASES_URL`   | Override URL for querying llvm available remote releases.                                                                                     | `none`   |                  |
| `LLVM_PREFIX`         | Resolved LLVM installation prefix containing bin/clang, bin/llvm-cov, bin/llvm-profdata, and bin/llvm-size.                                   | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
