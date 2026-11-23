# Zstandard (`_lib/utilities/zstd/`)

## Overview

Fast real-time lossless compression algorithm and zstd CLI offering high compression ratios.

- **Tier**: `T1` (`_lib/utilities/zstd/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `zstd`, `compressor`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/zstd/<version>)
./libscript.sh ls-remote zstd
./libscript.sh install zstd latest
./libscript.sh use zstd latest
./libscript.sh which zstd
./_lib/utilities/zstd/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote zstd
.\libscript.cmd install zstd latest
.\libscript.cmd use zstd latest
.\libscript.cmd which zstd
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/zstd/<version>`
  (default `~/.libscript/zstd/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ZSTD_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ZSTD_INSTALL_METHOD` | How to install zstd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `ZSTD_VERSION`        | Specific version of zstd to install.                                                                                                          | `latest`           | latest, lts      |
| `ZSTD_DOWNLOAD_URL`   | Override URL for downloading zstd binary or archive artifacts.                                                                                | `none`             |                  |
| `ZSTD_RELEASES_URL`   | Override URL for querying zstd available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
