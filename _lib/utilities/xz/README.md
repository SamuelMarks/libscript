# XZ Utils (`_lib/utilities/xz/`)

## Overview

General-purpose lossless data compression CLI and liblzma library utilizing the LZMA2 algorithm.

- **Tier**: `T1` (`_lib/utilities/xz/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `xz`, `lzma`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/xz/<version>)
./libscript.sh ls-remote xz
./libscript.sh install xz latest
./libscript.sh use xz latest
./libscript.sh which xz
./_lib/utilities/xz/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote xz
.\libscript.cmd install xz latest
.\libscript.cmd use xz latest
.\libscript.cmd which xz
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/xz/<version>`
  (default `~/.libscript/xz/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `XZ_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                 | Default  | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `XZ_INSTALL_METHOD` | How to install xz. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `XZ_VERSION`        | Specific version of xz to install.                                                                                                          | `latest` | latest, lts      |
| `XZ_DOWNLOAD_URL`   | Override URL for downloading xz binary or archive artifacts.                                                                                | `none`   |                  |
| `XZ_RELEASES_URL`   | Override URL for querying xz available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
