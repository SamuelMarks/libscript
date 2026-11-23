# systemd-boot UEFI Boot Manager (`_lib/bootloaders/systemd-boot/`)

## Overview

UEFI boot manager (bootctl and systemd-bootx64.efi / systemd-bootaa64.efi) supporting Type #1 Boot
Loader Specification entries and Type #2 UKIs.

- **Tier**: `T2` (`_lib/bootloaders/systemd-boot/`)
- **Capabilities**: `sysroot-package`, `bootloader`
- **Provides Virtual Capabilities**: `systemd-boot`, `bootctl`, `gummiboot`
- **Target OS Whitelist (`manifest.json`)**: `linux`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install systemd-boot latest
./libscript.sh systemd-boot --help
./_lib/bootloaders/systemd-boot/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd systemd-boot --help
.\_lib\bootloaders\systemd-boot\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `SYSTEMD_BOOT_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                                           | Default            | Aliases/Examples |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SYSTEMD_BOOT_INSTALL_METHOD` | How to install systemd-boot. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SYSTEMD_BOOT_VERSION`        | Specific version of systemd-boot to install.                                                                                                          | `latest`           | latest, stable   |
| `SYSTEMD_BOOT_DOWNLOAD_URL`   | Override URL for downloading systemd-boot binary or archive artifacts.                                                                                | `none`             |                  |
| `SYSTEMD_BOOT_RELEASES_URL`   | Override URL for querying systemd-boot available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
