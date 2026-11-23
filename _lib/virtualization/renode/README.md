# Renode Deterministic MCU/SoC Simulator (`_lib/virtualization/renode/`)

## Overview

Portable headless hardware/MCU/wireless multi-node simulation framework for Zephyr and FreeRTOS
across Linux, macOS, and Windows.

- **Tier**: `T1` (`_lib/virtualization/renode/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/renode/<version>)
./libscript.sh ls-remote renode
./libscript.sh install renode latest
./libscript.sh use renode latest
./libscript.sh which renode
./_lib/virtualization/renode/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote renode
.\libscript.cmd install renode latest
.\libscript.cmd use renode latest
.\libscript.cmd which renode
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/renode/<version>`
  (default `~/.libscript/renode/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `RENODE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RENODE_INSTALL_METHOD` | How to install renode. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `RENODE_VERSION`        | Specific version of renode to install.                                                                                                          | `1.15.3`           | latest, lts      |
| `RENODE_DOWNLOAD_URL`   | Override URL for downloading renode binary or archive artifacts.                                                                                | `none`             |                  |
| `RENODE_RELEASES_URL`   | Override URL for querying renode available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
