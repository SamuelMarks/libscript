# GNU xorriso (`_lib/utilities/xorriso/`)

## Overview

ISO-9660 and Rock Ridge filesystem image manipulation, El Torito bootable ISO creation, and burning
tool.

- **Tier**: `T1` (`_lib/utilities/xorriso/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `xorriso`, `iso-builder`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/xorriso/<version>)
./libscript.sh ls-remote xorriso
./libscript.sh install xorriso latest
./libscript.sh use xorriso latest
./libscript.sh which xorriso
./_lib/utilities/xorriso/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote xorriso
.\libscript.cmd install xorriso latest
.\libscript.cmd use xorriso latest
.\libscript.cmd which xorriso
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/xorriso/<version>`
  (default `~/.libscript/xorriso/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `XORRISO_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `XORRISO_INSTALL_METHOD` | How to install xorriso. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `XORRISO_VERSION`        | Specific version of xorriso to install.                                                                                                          | `latest` | latest, lts      |
| `XORRISO_DOWNLOAD_URL`   | Override URL for downloading xorriso binary or archive artifacts.                                                                                | `none`   |                  |
| `XORRISO_RELEASES_URL`   | Override URL for querying xorriso available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
