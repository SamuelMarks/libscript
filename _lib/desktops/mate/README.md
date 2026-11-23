# MATE Desktop Environment (`_lib/desktops/mate/`)

## Overview

MATE Desktop Environment session manager, panel, and traditional GTK desktop suite (mate-session).

- **Tier**: `T2` (`_lib/desktops/mate/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `mate`, `mate-desktop`, `mate-session`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `sunos`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `macos`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install mate latest
./libscript.sh mate --help
./_lib/desktops/mate/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd mate --help
.\_lib\desktops\mate\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `MATE_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MATE_INSTALL_METHOD` | How to install mate. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `MATE_VERSION`        | Specific version of mate to install.                                                                                                          | `latest`           | latest, stable   |
| `MATE_DOWNLOAD_URL`   | Override URL for downloading mate binary or archive artifacts.                                                                                | `none`             |                  |
| `MATE_RELEASES_URL`   | Override URL for querying mate available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
