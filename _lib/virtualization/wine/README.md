# WINE Win32 Compatibility Layer (`_lib/virtualization/wine/`)

## Overview

WINE 9+ Win32 runtime and wineserver daemon for unconfounded warm and cold baseline evaluations.

- **Tier**: `T1` (`_lib/virtualization/wine/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `wine`, `wineserver`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`, `freebsd`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/wine/<version>)
./libscript.sh ls-remote wine
./libscript.sh install wine latest
./libscript.sh use wine latest
./libscript.sh which wine
./_lib/virtualization/wine/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote wine
.\libscript.cmd install wine latest
.\libscript.cmd use wine latest
.\libscript.cmd which wine
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/wine/<version>`
  (default `~/.libscript/wine/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `WINE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `WINE_INSTALL_METHOD` | How to install wine. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `WINE_VERSION`        | Specific version of wine to install.                                                                                                          | `latest` | latest, lts      |
| `WINE_DOWNLOAD_URL`   | Override URL for downloading wine binary or archive artifacts.                                                                                | `none`   |                  |
| `WINE_RELEASES_URL`   | Override URL for querying wine available remote releases.                                                                                     | `none`   |                  |
| `WINE_PREFIX_DIR`     | Isolated WINEPREFIX directory exported when activating the wine component.                                                                    | ``       |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
