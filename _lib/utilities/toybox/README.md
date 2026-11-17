# toybox

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `toybox` component (part
of `_utilities`) within the LibScript ecosystem. All-in-one BSD-licensed POSIX, Windows native
(MSVC), and MS-DOS command-line utility suite.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Toybox**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install toybox
libscript uninstall toybox
```

**Start / Stop (if configured as a background service):**

```sh
libscript start toybox
libscript stop toybox
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker toybox
```

_Note: On Unix environments, you can also use `./cli.sh install toybox`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                                                       | Default            | Aliases/Examples |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TOYBOX_INSTALL_METHOD` | How to install toybox. 'libscript_native' uses isolated version dirs (dos32 on MS-DOS, PE on Windows, static on Linux), 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TOYBOX_VERSION`        | Specific version of toybox to install (e.g., 0.8.15 on Windows/MS-DOS or latest).                                                                                                                 | `latest`           | latest, lts      |
| `TOYBOX_DOWNLOAD_URL`   | Override URL for downloading toybox binary or archive artifacts.                                                                                                                                  | `none`             |                  |
| `TOYBOX_RELEASES_URL`   | Override URL for querying toybox available remote releases.                                                                                                                                       | `none`             |                  |
| `TOYBOX_INSTALL_SHIMS`  | When set to '1', materializes per-applet hardlinks or .bat/.exe trampolines in bin/ when freebsd-usr-bin is not installed.                                                                        | `0`                |                  |

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
