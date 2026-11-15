# grub

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `grub` component (part of
`_bootloaders`) within the LibScript ecosystem. Standalone GNU GRand Unified Bootloader v2
(grub-install, grub-mkconfig, grub-mkstandalone) for BIOS and UEFI systems.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **GNU GRUB 2 Bootloader**. It
is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install grub
libscript uninstall grub
```

**Start / Stop (if configured as a background service):**

```sh
libscript start grub
libscript stop grub
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker grub
```

_Note: On Unix environments, you can also use `./cli.sh install grub`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GRUB_INSTALL_METHOD` | How to install grub. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GRUB_VERSION`        | Specific version of grub to install.                                                                                                          | `latest`           | latest, stable   |
| `GRUB_DOWNLOAD_URL`   | Override URL for downloading grub binary or archive artifacts.                                                                                | `none`             |                  |
| `GRUB_RELEASES_URL`   | Override URL for querying grub available remote releases.                                                                                     | `none`             |                  |

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
