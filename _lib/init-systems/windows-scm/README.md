# windows-scm

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `windows-scm` component
(part of `_init-systems`) within the LibScript ecosystem. Windows Service Control Manager (SCM /
sc.exe) native service lifecycle adapter and cross-platform compatibility shim.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Windows Service Control
Manager (sc.exe) Adapter**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install windows-scm
libscript uninstall windows-scm
```

**Start / Stop (if configured as a background service):**

```sh
libscript start windows-scm
libscript stop windows-scm
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker windows-scm
```

_Note: On Unix environments, you can also use `./cli.sh install windows-scm`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                          | Default            | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WINDOWS_SCM_INSTALL_METHOD` | How to install windows-scm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `WINDOWS_SCM_VERSION`        | Specific version of windows-scm to install.                                                                                                          | `latest`           | latest, stable   |
| `WINDOWS_SCM_DOWNLOAD_URL`   | Override URL for downloading windows-scm binary or archive artifacts.                                                                                | `none`             |                  |
| `WINDOWS_SCM_RELEASES_URL`   | Override URL for querying windows-scm available remote releases.                                                                                     | `none`             |                  |

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
