# ARM Bare-Metal GNU Toolchain (`_lib/toolchains/arm-none-eabi-gcc/`)

## Overview

Bare-metal ARM Cortex-M/Cortex-R GNU embedded C/C++ cross-toolchain (arm-none-eabi-gcc, objcopy,
gdb, newlib, picolibc).

- **Tier**: `T1` (`_lib/toolchains/arm-none-eabi-gcc/`)
- **Capabilities**: `userland-package`, `cross-toolchain`
- **Provides Virtual Capabilities**: `arm-none-eabi-gcc`, `arm-none-eabi-objcopy`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/arm-none-eabi-gcc/<version>)
./libscript.sh ls-remote arm-none-eabi-gcc
./libscript.sh install arm-none-eabi-gcc latest
./libscript.sh use arm-none-eabi-gcc latest
./libscript.sh which arm-none-eabi-gcc
./_lib/toolchains/arm-none-eabi-gcc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote arm-none-eabi-gcc
.\libscript.cmd install arm-none-eabi-gcc latest
.\libscript.cmd use arm-none-eabi-gcc latest
.\libscript.cmd which arm-none-eabi-gcc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/arm-none-eabi-gcc/<version>` (default
  `~/.libscript/arm-none-eabi-gcc/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `ARM_NONE_EABI_GCC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                | Default  | Aliases/Examples |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `ARM_NONE_EABI_GCC_INSTALL_METHOD` | How to install arm-none-eabi-gcc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `ARM_NONE_EABI_GCC_VERSION`        | Specific version of arm-none-eabi-gcc to install.                                                                                                          | `13.3.1` | latest, lts      |
| `ARM_NONE_EABI_GCC_DOWNLOAD_URL`   | Override URL for downloading arm-none-eabi-gcc binary or archive artifacts.                                                                                | `none`   |                  |
| `ARM_NONE_EABI_GCC_RELEASES_URL`   | Override URL for querying arm-none-eabi-gcc available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
