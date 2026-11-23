# zlib Compression Library (`_lib/utilities/zlib/`)

## Overview

Standalone version manager and custom-compiler source builder for zlib (pinned default 1.3.1) with
upstream make test / CTest verification.

- **Tier**: `T1` (`_lib/utilities/zlib/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/zlib/<version>)
./libscript.sh ls-remote zlib
./libscript.sh install zlib latest
./libscript.sh use zlib latest
./libscript.sh which zlib
./_lib/utilities/zlib/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote zlib
.\libscript.cmd install zlib latest
.\libscript.cmd use zlib latest
.\libscript.cmd which zlib
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/zlib/<version>`
  (default `~/.libscript/zlib/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ZLIB_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default       | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `ZLIB_INSTALL_METHOD` | How to install zlib. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `ZLIB_VERSION`        | Specific version of zlib to install.                                                                                                          | `1.3.1`       | latest, lts      |
| `ZLIB_DOWNLOAD_URL`   | Override URL for downloading zlib binary or archive artifacts.                                                                                | `none`        |                  |
| `ZLIB_RELEASES_URL`   | Override URL for querying zlib available remote releases.                                                                                     | `none`        |                  |
| `ZLIB_RUN_TESTS`      | Whether to execute upstream zlib make test / ctest checks after building from source.                                                         | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
