# renode

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `renode` component (part
of `_orchestration`) within the LibScript ecosystem. Portable headless hardware/MCU/wireless
multi-node simulation framework for Zephyr and FreeRTOS across Linux, macOS, and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Renode Deterministic
MCU/SoC Simulator**. It is designed to be executed via the global `libscript.sh` router or directly
via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install renode
libscript uninstall renode
```

**Start / Stop (if configured as a background service):**

```sh
libscript start renode
libscript stop renode
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker renode
```

_Note: On Unix environments, you can also use `./cli.sh install renode`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RENODE_INSTALL_METHOD` | How to install renode. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `RENODE_VERSION`        | Specific version of renode to install.                                                                                                          | `1.15.3`           | latest, lts      |
| `RENODE_DOWNLOAD_URL`   | Override URL for downloading renode binary or archive artifacts.                                                                                | `none`             |                  |
| `RENODE_RELEASES_URL`   | Override URL for querying renode available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
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
