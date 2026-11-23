# libarchive (bsdtar) (`_lib/utilities/libarchive/`)

## Overview

Multi-format streaming archive library and bsdtar command-line utility.

- **Tier**: `T1` (`_lib/utilities/libarchive/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `libarchive`, `bsdtar`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/libarchive/<version>)
./libscript.sh ls-remote libarchive
./libscript.sh install libarchive latest
./libscript.sh use libarchive latest
./libscript.sh which libarchive
./_lib/utilities/libarchive/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote libarchive
.\libscript.cmd install libarchive latest
.\libscript.cmd use libarchive latest
.\libscript.cmd which libarchive
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/libarchive/<version>`
  (default `~/.libscript/libarchive/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `LIBARCHIVE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default  | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `LIBARCHIVE_INSTALL_METHOD` | How to install libarchive. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `LIBARCHIVE_VERSION`        | Specific version of libarchive to install.                                                                                                          | `3.7.7`  | latest, lts      |
| `LIBARCHIVE_DOWNLOAD_URL`   | Override URL for downloading libarchive binary or archive artifacts.                                                                                | `none`   |                  |
| `LIBARCHIVE_RELEASES_URL`   | Override URL for querying libarchive available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
