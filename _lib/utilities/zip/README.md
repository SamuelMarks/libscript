# Info-ZIP Zip (`_lib/utilities/zip/`)

## Overview

Portable Info-ZIP compression and file packaging utility producing standard .zip archives.

- **Tier**: `T1` (`_lib/utilities/zip/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `zip`, `zip-archiver`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/zip/<version>)
./libscript.sh ls-remote zip
./libscript.sh install zip latest
./libscript.sh use zip latest
./libscript.sh which zip
./_lib/utilities/zip/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote zip
.\libscript.cmd install zip latest
.\libscript.cmd use zip latest
.\libscript.cmd which zip
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/zip/<version>`
  (default `~/.libscript/zip/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ZIP_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `ZIP_INSTALL_METHOD` | How to install zip. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `ZIP_VERSION`        | Specific version of zip to install.                                                                                                          | `latest` | latest, lts      |
| `ZIP_DOWNLOAD_URL`   | Override URL for downloading zip binary or archive artifacts.                                                                                | `none`   |                  |
| `ZIP_RELEASES_URL`   | Override URL for querying zip available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
