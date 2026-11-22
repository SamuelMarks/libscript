# riscv-none-elf-gcc

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `riscv-none-elf-gcc`
component (part of `_toolchains`) within the LibScript ecosystem. Bare-metal 32/64-bit RISC-V
multilib (rv32imac/rv64imac) embedded GNU cross-toolchain with newlib and picolibc support.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **RISC-V Bare-Metal GNU
Toolchain**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install riscv-none-elf-gcc
libscript uninstall riscv-none-elf-gcc
```

**Start / Stop (if configured as a background service):**

```sh
libscript start riscv-none-elf-gcc
libscript stop riscv-none-elf-gcc
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker riscv-none-elf-gcc
```

_Note: On Unix environments, you can also use `./cli.sh install riscv-none-elf-gcc`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                            | Description                                                                                                                                                 | Default  | Aliases/Examples |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `RISCV_NONE_ELF_GCC_INSTALL_METHOD` | How to install riscv-none-elf-gcc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `RISCV_NONE_ELF_GCC_VERSION`        | Specific version of riscv-none-elf-gcc to install.                                                                                                          | `13.2.0` | latest, lts      |
| `RISCV_NONE_ELF_GCC_DOWNLOAD_URL`   | Override URL for downloading riscv-none-elf-gcc binary or archive artifacts.                                                                                | `none`   |                  |
| `RISCV_NONE_ELF_GCC_RELEASES_URL`   | Override URL for querying riscv-none-elf-gcc available remote releases.                                                                                     | `none`   |                  |

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
