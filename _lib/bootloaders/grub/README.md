# GNU GRUB 2 Bootloader (`_lib/bootloaders/grub/`)

## Overview

Standalone GNU GRand Unified Bootloader v2 (grub-install, grub-mkconfig, grub-mkstandalone) for BIOS
and UEFI systems.

- **Tier**: `T2` (`_lib/bootloaders/grub/`)
- **Capabilities**: `sysroot-package`, `bootloader`
- **Provides Virtual Capabilities**: `grub`, `grub2`, `grub-install`, `grub-mkconfig`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `sunos`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install grub latest
./libscript.sh grub --help
./_lib/bootloaders/grub/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd grub --help
.\_lib\bootloaders\grub\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `GRUB_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GRUB_INSTALL_METHOD` | How to install grub. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GRUB_VERSION`        | Specific version of grub to install.                                                                                                          | `latest`           | latest, stable   |
| `GRUB_DOWNLOAD_URL`   | Override URL for downloading grub binary or archive artifacts.                                                                                | `none`             |                  |
| `GRUB_RELEASES_URL`   | Override URL for querying grub available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
