# i3

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `i3` component (part of
`_desktops`) within the LibScript ecosystem. Dynamic tiling X11 window manager (i3, i3-msg, i3bar)
designed for keyboard-driven workflows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **i3 Tiling Window Manager**.
It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install i3
libscript uninstall i3
```

**Start / Stop (if configured as a background service):**

```sh
libscript start i3
libscript stop i3
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker i3
```

_Note: On Unix environments, you can also use `./cli.sh install i3`. On Windows, use `libscript.cmd`
or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                 | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `I3_INSTALL_METHOD` | How to install i3. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `I3_VERSION`        | Specific version of i3 to install.                                                                                                          | `latest`           | latest, stable   |
| `I3_DOWNLOAD_URL`   | Override URL for downloading i3 binary or archive artifacts.                                                                                | `none`             |                  |
| `I3_RELEASES_URL`   | Override URL for querying i3 available remote releases.                                                                                     | `none`             |                  |

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
