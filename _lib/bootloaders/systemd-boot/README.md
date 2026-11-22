# systemd-boot

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `systemd-boot` component
(part of `_bootloaders`) within the LibScript ecosystem. UEFI boot manager (bootctl and
systemd-bootx64.efi / systemd-bootaa64.efi) supporting Type #1 Boot Loader Specification entries and
Type #2 UKIs.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **systemd-boot UEFI Boot
Manager**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install systemd-boot
libscript uninstall systemd-boot
```

**Start / Stop (if configured as a background service):**

```sh
libscript start systemd-boot
libscript stop systemd-boot
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker systemd-boot
```

_Note: On Unix environments, you can also use `./cli.sh install systemd-boot`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                                           | Default            | Aliases/Examples |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SYSTEMD_BOOT_INSTALL_METHOD` | How to install systemd-boot. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SYSTEMD_BOOT_VERSION`        | Specific version of systemd-boot to install.                                                                                                          | `latest`           | latest, stable   |
| `SYSTEMD_BOOT_DOWNLOAD_URL`   | Override URL for downloading systemd-boot binary or archive artifacts.                                                                                | `none`             |                  |
| `SYSTEMD_BOOT_RELEASES_URL`   | Override URL for querying systemd-boot available remote releases.                                                                                     | `none`             |                  |

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
