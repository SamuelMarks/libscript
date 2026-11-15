# msitools

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `msitools` component (part
of `_toolchains`) within the LibScript ecosystem. GNOME msitools suite providing wixl, msiinfo,
msibuild, msidump, and msiextract for MSI authoring baselines.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **GNOME msitools (wixl)**. It
is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install msitools
libscript uninstall msitools
```

**Start / Stop (if configured as a background service):**

```sh
libscript start msitools
libscript stop msitools
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker msitools
```

_Note: On Unix environments, you can also use `./cli.sh install msitools`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `MSITOOLS_INSTALL_METHOD` | How to install msitools. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `MSITOOLS_VERSION`        | Specific version of msitools to install.                                                                                                          | `0.106`  | latest, lts      |
| `MSITOOLS_DOWNLOAD_URL`   | Override URL for downloading msitools binary or archive artifacts.                                                                                | `none`   |                  |
| `MSITOOLS_RELEASES_URL`   | Override URL for querying msitools available remote releases.                                                                                     | `none`   |                  |

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
