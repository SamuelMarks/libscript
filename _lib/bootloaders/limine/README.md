# Limine Bootloader (`_lib/bootloaders/limine/`)

## Overview

Modern, portable, multiprotocol UEFI and BIOS bootloader supporting Linux, Limine boot protocol,
multiboot2, and chainloading.

- **Tier**: `T2` (`_lib/bootloaders/limine/`)
- **Capabilities**: `sysroot-package`, `bootloader`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `sunos`,
  `macos`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install limine latest
./libscript.sh limine --help
./_lib/bootloaders/limine/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd limine --help
.\_lib\bootloaders\limine\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `LIMINE_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIMINE_INSTALL_METHOD` | How to install limine. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LIMINE_VERSION`        | Specific version of limine to install.                                                                                                          | `latest`           | latest, stable   |
| `LIMINE_DOWNLOAD_URL`   | Override URL for downloading limine binary or archive artifacts.                                                                                | `none`             |                  |
| `LIMINE_RELEASES_URL`   | Override URL for querying limine available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
