# Device Tree Compiler (dtc) (`_lib/toolchains/dtc/`)

## Overview

Device Tree Compiler (dtc) and libfdt utilities for compiling and overlaying Zephyr and embedded
hardware Devicetrees.

- **Tier**: `T1` (`_lib/toolchains/dtc/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `dtc`, `fdtget`, `fdtput`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/dtc/<version>)
./libscript.sh ls-remote dtc
./libscript.sh install dtc latest
./libscript.sh use dtc latest
./libscript.sh which dtc
./_lib/toolchains/dtc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote dtc
.\libscript.cmd install dtc latest
.\libscript.cmd use dtc latest
.\libscript.cmd which dtc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/dtc/<version>`
  (default `~/.libscript/dtc/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `DTC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `DTC_INSTALL_METHOD` | How to install dtc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `DTC_VERSION`        | Specific version of dtc to install.                                                                                                          | `1.7.1`  | latest, lts      |
| `DTC_DOWNLOAD_URL`   | Override URL for downloading dtc binary or archive artifacts.                                                                                | `none`   |                  |
| `DTC_RELEASES_URL`   | Override URL for querying dtc available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
