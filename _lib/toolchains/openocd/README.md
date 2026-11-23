# OpenOCD On-Chip Debugger (`_lib/toolchains/openocd/`)

## Overview

Open On-Chip Debugger providing SWD/JTAG hardware flashing and GDB remote server support for ARM,
RISC-V, and Xtensa targets.

- **Tier**: `T1` (`_lib/toolchains/openocd/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/openocd/<version>)
./libscript.sh ls-remote openocd
./libscript.sh install openocd latest
./libscript.sh use openocd latest
./libscript.sh which openocd
./_lib/toolchains/openocd/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote openocd
.\libscript.cmd install openocd latest
.\libscript.cmd use openocd latest
.\libscript.cmd which openocd
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/openocd/<version>`
  (default `~/.libscript/openocd/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OPENOCD_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `OPENOCD_INSTALL_METHOD` | How to install openocd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `OPENOCD_VERSION`        | Specific version of openocd to install.                                                                                                          | `0.12.0` | latest, lts      |
| `OPENOCD_DOWNLOAD_URL`   | Override URL for downloading openocd binary or archive artifacts.                                                                                | `none`   |                  |
| `OPENOCD_RELEASES_URL`   | Override URL for querying openocd available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
