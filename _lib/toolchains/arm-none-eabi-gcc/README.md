# arm-none-eabi-gcc

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `arm-none-eabi-gcc`
component (part of `_toolchains`) within the LibScript ecosystem. Bare-metal ARM Cortex-M/Cortex-R
GNU embedded C/C++ cross-toolchain (arm-none-eabi-gcc, objcopy, gdb, newlib, picolibc).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **ARM Bare-Metal GNU
Toolchain**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install arm-none-eabi-gcc
libscript uninstall arm-none-eabi-gcc
```

**Start / Stop (if configured as a background service):**

```sh
libscript start arm-none-eabi-gcc
libscript stop arm-none-eabi-gcc
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker arm-none-eabi-gcc
```

_Note: On Unix environments, you can also use `./cli.sh install arm-none-eabi-gcc`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

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

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
