# freedos

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `freedos` component (part
of `_kernel`) within the LibScript ecosystem. FreeDOS GPL-2.0 16/32-bit FAT12/FAT16/FAT32 kernel
(KERNEL.SYS), boot sectors, and FreeCOM (COMMAND.COM) cross-builder via OpenWatcom and NASM.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **FreeDOS Kernel & FreeCOM
Command Interpreter**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install freedos
libscript uninstall freedos
```

**Start / Stop (if configured as a background service):**

```sh
libscript start freedos
libscript stop freedos
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker freedos
```

_Note: On Unix environments, you can also use `./cli.sh install freedos`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `FREEDOS_INSTALL_METHOD` | How to install freedos. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FREEDOS_VERSION`        | Specific version of freedos to install.                                                                                                          | `1.4`              | latest, lts      |
| `FREEDOS_DOWNLOAD_URL`   | Override URL for downloading freedos binary or archive artifacts.                                                                                | `none`             |                  |
| `FREEDOS_RELEASES_URL`   | Override URL for querying freedos available remote releases.                                                                                     | `none`             |                  |
| `FREEDOS_BUILD_MODE`     | Kernel synthesis mode: from-source (OpenWatcom + NASM) or repack (official FreeDOS kernel archive).                                              | `from-source`      |                  |
| `FREEDOS_CPU_TARGET`     | Target x86 CPU generation for KERNEL.SYS (86, 186, or 386).                                                                                      | `386`              |                  |
| `FREEDOS_FAT_SUPPORT`    | Maximum FAT filesystem width compiled into KERNEL.SYS (fat16 or fat32).                                                                          | `fat32`            |                  |
| `FREEDOS_SERIAL_CONSOLE` | Enable COM1 serial console telemetry support during boot staging when set to 1.                                                                  | `1`                |                  |

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
