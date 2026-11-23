# rEFInd UEFI Boot Manager (`_lib/bootloaders/refind/`)

## Overview

Graphical UEFI boot manager and automatic EFI OS/kernel discovery tool (refind-install).

- **Tier**: `T2` (`_lib/bootloaders/refind/`)
- **Capabilities**: `sysroot-package`, `bootloader`
- **Provides Virtual Capabilities**: `refind`, `refind-install`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `macos`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `sunos`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install refind latest
./libscript.sh refind --help
./_lib/bootloaders/refind/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd refind --help
.\_lib\bootloaders\refind\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `REFIND_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `REFIND_INSTALL_METHOD` | How to install refind. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `REFIND_VERSION`        | Specific version of refind to install.                                                                                                          | `latest`           | latest, stable   |
| `REFIND_DOWNLOAD_URL`   | Override URL for downloading refind binary or archive artifacts.                                                                                | `none`             |                  |
| `REFIND_RELEASES_URL`   | Override URL for querying refind available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
