# sccache (`_lib/toolchains/sccache/`)

## Overview

Shared compilation cache for C, C++, Rust, and CUDA.

- **Tier**: `T1` (`_lib/toolchains/sccache/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `sccache`, `compiler-cache`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/sccache/<version>)
./libscript.sh ls-remote sccache
./libscript.sh install sccache latest
./libscript.sh use sccache latest
./libscript.sh which sccache
./_lib/toolchains/sccache/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote sccache
.\libscript.cmd install sccache latest
.\libscript.cmd use sccache latest
.\libscript.cmd which sccache
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/sccache/<version>`
  (default `~/.libscript/sccache/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `SCCACHE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `SCCACHE_INSTALL_METHOD` | How to install sccache. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SCCACHE_VERSION`        | Specific version of sccache to install.                                                                                                          | `latest`           | latest, 0.8.2    |
| `SCCACHE_DOWNLOAD_URL`   | Override URL for downloading sccache binary or archive artifacts.                                                                                | `none`             |                  |
| `SCCACHE_RELEASES_URL`   | Override URL for querying sccache available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
