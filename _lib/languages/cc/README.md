# C Compiler (`_lib/languages/cc/`)

## Overview

Generic C compiler interface.

- **Tier**: `T1` (`_lib/languages/cc/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `cc`, `toolchain`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/cc/<version>)
./libscript.sh ls-remote cc
./libscript.sh install cc latest
./libscript.sh use cc latest
./libscript.sh which cc
./_lib/languages/cc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote cc
.\libscript.cmd install cc latest
.\libscript.cmd use cc latest
.\libscript.cmd which cc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/cc/<version>`
  (default `~/.libscript/cc/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                                                                        | Default   | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------- |
| `CC_INSTALL_METHOD`  | Installation strategy for cc: 'libscript_native' installs into isolated versioned directories, 'from-source' compiles from source archives, and 'system' delegates to the host OS package manager. | `system`  |                  |
| `CC_VERSION`         | Version of C Compiler to install                                                                                                                                                                   | `latest`  |                  |
| `CC_BACKEND`         | Active C compiler backend routed by cc ('default', 'gcc', 'clang', 'tcc', 'edgcpp', 'custom-cc').                                                                                                  | `default` |                  |
| `CC_PKG_MGR`         | Explicit package manager override for CC installation.                                                                                                                                             | `none`    |                  |
| `CC_BUILD_TOOLCHAIN` | Bootstrap C toolchain used when building CC from source.                                                                                                                                           | `default` |                  |
| `CC_DOWNLOAD_URL`    | Override URL for downloading cc binary or archive artifacts.                                                                                                                                       | `none`    |                  |
| `CC_RELEASES_URL`    | Override URL for querying cc available remote releases.                                                                                                                                            | `none`    |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
