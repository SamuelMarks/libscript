# RISC-V Bare-Metal GNU Toolchain (`_lib/toolchains/riscv-none-elf-gcc/`)

## Overview

Bare-metal 32/64-bit RISC-V multilib (rv32imac/rv64imac) embedded GNU cross-toolchain with newlib
and picolibc support.

- **Tier**: `T1` (`_lib/toolchains/riscv-none-elf-gcc/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `riscv64-unknown-elf-gcc`, `riscv-none-elf-gcc`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/riscv-none-elf-gcc/<version>)
./libscript.sh ls-remote riscv-none-elf-gcc
./libscript.sh install riscv-none-elf-gcc latest
./libscript.sh use riscv-none-elf-gcc latest
./libscript.sh which riscv-none-elf-gcc
./_lib/toolchains/riscv-none-elf-gcc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote riscv-none-elf-gcc
.\libscript.cmd install riscv-none-elf-gcc latest
.\libscript.cmd use riscv-none-elf-gcc latest
.\libscript.cmd which riscv-none-elf-gcc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/riscv-none-elf-gcc/<version>` (default
  `~/.libscript/riscv-none-elf-gcc/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `RISCV_NONE_ELF_GCC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

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

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
