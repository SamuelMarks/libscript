# Windows Subsystem for Linux (WSL) (`_lib/virtualization/wsl/`)

## Overview

Microsoft Windows Subsystem for Linux (wsl.exe) distribution lifecycle and kernel manager.

- **Tier**: `T1` (`_lib/virtualization/wsl/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `wsl`, `wsl.exe`
- **Target OS Whitelist (`manifest.json`)**: `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/wsl/<version>)
./libscript.sh ls-remote wsl
./libscript.sh install wsl latest
./libscript.sh use wsl latest
./libscript.sh which wsl
./_lib/virtualization/wsl/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote wsl
.\libscript.cmd install wsl latest
.\libscript.cmd use wsl latest
.\libscript.cmd which wsl
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/wsl/<version>`
  (default `~/.libscript/wsl/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `WSL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WSL_INSTALL_METHOD` | How to install wsl. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `WSL_VERSION`        | Specific version of wsl to install.                                                                                                          | `latest`           | latest, stable   |
| `WSL_DOWNLOAD_URL`   | Override URL for downloading wsl binary or archive artifacts.                                                                                | `none`             |                  |
| `WSL_RELEASES_URL`   | Override URL for querying wsl available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
