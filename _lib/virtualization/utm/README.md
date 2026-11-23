# UTM Virtual Machines for macOS (`_lib/virtualization/utm/`)

## Overview

UTM (utmctl) QEMU and Apple Virtualization.framework virtual machine frontend and CLI controller for
macOS.

- **Tier**: `T1` (`_lib/virtualization/utm/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `utm`, `utmctl`
- **Target OS Whitelist (`manifest.json`)**: `macos`, `darwin`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/utm/<version>)
./libscript.sh ls-remote utm
./libscript.sh install utm latest
./libscript.sh use utm latest
./libscript.sh which utm
./_lib/virtualization/utm/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote utm
.\libscript.cmd install utm latest
.\libscript.cmd use utm latest
.\libscript.cmd which utm
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/utm/<version>`
  (default `~/.libscript/utm/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `UTM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `UTM_INSTALL_METHOD` | How to install utm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `UTM_VERSION`        | Specific version of utm to install.                                                                                                          | `latest`           | latest, stable   |
| `UTM_DOWNLOAD_URL`   | Override URL for downloading utm binary or archive artifacts.                                                                                | `none`             |                  |
| `UTM_RELEASES_URL`   | Override URL for querying utm available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
