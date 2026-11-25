# kvikdos

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `kvikdos` component (part
of `_toolchains`) within the LibScript ecosystem. Zero-dependency headless 8086 real-mode DOS CLI
runner (C89 INT 21h emulator + win-cmd-asm vm8086 bridge) for executing 16-bit DOS compilers (MASM,
NMAKE, LINK, ASM.COM).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Headless 8086 Real-Mode DOS
CLI Build Runner**. It is designed to be executed via the global `libscript.sh` router or directly
via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install kvikdos
libscript uninstall kvikdos
```

**Start / Stop (if configured as a background service):**

```sh
libscript start kvikdos
libscript stop kvikdos
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker kvikdos
```

_Note: On Unix environments, you can also use `./cli.sh install kvikdos`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `KVIKDOS_INSTALL_METHOD` | How to install kvikdos. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `KVIKDOS_VERSION`        | Specific version of kvikdos to install.                                                                                                          | `0.1.0`            | latest, lts      |
| `KVIKDOS_DOWNLOAD_URL`   | Override URL for downloading kvikdos binary or archive artifacts.                                                                                | `none`             |                  |
| `KVIKDOS_RELEASES_URL`   | Override URL for querying kvikdos available remote releases.                                                                                     | `none`             |                  |
| `KVIKDOS_BACKEND`        | Execution backend selection: auto, vm8086 (delegating to win-cmd-asm), or c89-emu (portable zero-dependency 8086 CPU + INT 21h emulator).        | `auto`             |                  |
| `KVIKDOS_MAX_STEPS`      | Maximum 8086 instruction budget before aborting a runaway 16-bit tool invocation.                                                                | `500000000`        |                  |
| `KVIKDOS_MEM_KB`         | Conventional RAM size in KiB exposed to guest 16-bit DOS build utilities.                                                                        | `640`              |                  |

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
