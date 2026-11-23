# ImageMagick (`_lib/utilities/imagemagick/`)

## Overview

Raster and vector digital image creation, editing, composition, and conversion CLI suite (magick).

- **Tier**: `T1` (`_lib/utilities/imagemagick/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `imagemagick`, `magick`, `image-converter`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/imagemagick/<version>)
./libscript.sh ls-remote imagemagick
./libscript.sh install imagemagick latest
./libscript.sh use imagemagick latest
./libscript.sh which imagemagick
./_lib/utilities/imagemagick/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote imagemagick
.\libscript.cmd install imagemagick latest
.\libscript.cmd use imagemagick latest
.\libscript.cmd which imagemagick
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/imagemagick/<version>` (default `~/.libscript/imagemagick/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `IMAGEMAGICK_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                          | Default  | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `IMAGEMAGICK_INSTALL_METHOD` | How to install imagemagick. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `IMAGEMAGICK_VERSION`        | Specific version of imagemagick to install.                                                                                                          | `latest` | latest, lts      |
| `IMAGEMAGICK_DOWNLOAD_URL`   | Override URL for downloading imagemagick binary or archive artifacts.                                                                                | `none`   |                  |
| `IMAGEMAGICK_RELEASES_URL`   | Override URL for querying imagemagick available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
