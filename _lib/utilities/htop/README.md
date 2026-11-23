# htop (`_lib/utilities/htop/`)

## Overview

Cross-platform interactive ncurses system process viewer and resource monitor.

- **Tier**: `T1` (`_lib/utilities/htop/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `htop`, `process-viewer`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/htop/<version>)
./libscript.sh ls-remote htop
./libscript.sh install htop latest
./libscript.sh use htop latest
./libscript.sh which htop
./_lib/utilities/htop/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote htop
.\libscript.cmd install htop latest
.\libscript.cmd use htop latest
.\libscript.cmd which htop
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/htop/<version>`
  (default `~/.libscript/htop/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `HTOP_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `HTOP_INSTALL_METHOD` | How to install htop. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `HTOP_VERSION`        | Specific version of htop to install.                                                                                                          | `latest` | latest, lts      |
| `HTOP_DOWNLOAD_URL`   | Override URL for downloading htop binary or archive artifacts.                                                                                | `none`   |                  |
| `HTOP_RELEASES_URL`   | Override URL for querying htop available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
