# openocd

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `openocd` component (part
of `_toolchains`) within the LibScript ecosystem. Open On-Chip Debugger providing SWD/JTAG hardware
flashing and GDB remote server support for ARM, RISC-V, and Xtensa targets.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OpenOCD On-Chip Debugger**.
It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install openocd
libscript uninstall openocd
```

**Start / Stop (if configured as a background service):**

```sh
libscript start openocd
libscript stop openocd
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker openocd
```

_Note: On Unix environments, you can also use `./cli.sh install openocd`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `OPENOCD_INSTALL_METHOD` | How to install openocd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `OPENOCD_VERSION`        | Specific version of openocd to install.                                                                                                          | `0.12.0` | latest, lts      |
| `OPENOCD_DOWNLOAD_URL`   | Override URL for downloading openocd binary or archive artifacts.                                                                                | `none`   |                  |
| `OPENOCD_RELEASES_URL`   | Override URL for querying openocd available remote releases.                                                                                     | `none`   |                  |

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
