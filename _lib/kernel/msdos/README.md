# msdos

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `msdos` component (part of
`_kernel`) within the LibScript ecosystem. Microsoft MIT-licensed MS-DOS 1.25, 2.0, and 4.00 kernel
source builder with CP437 normalizer, 86-DOS/MASM lowerer, clean-room NASM IO.SYS/MBR/VBR shims, and
repack support.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Microsoft MIT MS-DOS Kernel
(1.25, 2.0, 4.00)**. It is designed to be executed via the global `libscript.sh` router or directly
via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install msdos
libscript uninstall msdos
```

**Start / Stop (if configured as a background service):**

```sh
libscript start msdos
libscript stop msdos
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker msdos
```

_Note: On Unix environments, you can also use `./cli.sh install msdos`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                    | Default            | Aliases/Examples |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MSDOS_INSTALL_METHOD`    | How to install msdos. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `MSDOS_VERSION`           | Specific version of msdos to install.                                                                                                          | `4.0`              | latest, lts      |
| `MSDOS_DOWNLOAD_URL`      | Override URL for downloading msdos binary or archive artifacts.                                                                                | `none`             |                  |
| `MSDOS_RELEASES_URL`      | Override URL for querying msdos available remote releases.                                                                                     | `none`             |                  |
| `MSDOS_BUILD_MODE`        | Kernel synthesis mode: from-source (NASM clean-room IO.SYS + kvikdos/scp2nasm) or repack.                                                      | `from-source`      |                  |
| `MSDOS_CPU_FLAVOR`        | Guest CPU target flavor (8086 for 1.25/2.0 real mode or 386 for 4.00 with DPMI).                                                               | `386`              |                  |
| `MSDOS_SERIAL_COM1`       | Configure clean-room IO.SYS AUX/CON hooks and boot scripts for COM1 serial telemetry when set to 1.                                            | `1`                |                  |
| `MSDOS_ASSEMBLER_BACKEND` | Assembler backend for clean-room BIOS/boot modules and lowered sources (nasm, jwasm, fasm, or kvikdos).                                        | `nasm`             |                  |

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
