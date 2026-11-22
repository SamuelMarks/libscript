# ly

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `ly` component (part of
`_display-managers`) within the LibScript ecosystem. Lightweight ncurses-like terminal user
interface (TUI) display manager for Linux and BSD supporting Wayland and X11.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Ly TUI Display Manager**.
It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install ly
libscript uninstall ly
```

**Start / Stop (if configured as a background service):**

```sh
libscript start ly
libscript stop ly
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker ly
```

_Note: On Unix environments, you can also use `./cli.sh install ly`. On Windows, use `libscript.cmd`
or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                 | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LY_INSTALL_METHOD` | How to install ly. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LY_VERSION`        | Specific version of ly to install.                                                                                                          | `latest`           | latest, stable   |
| `LY_DOWNLOAD_URL`   | Override URL for downloading ly binary or archive artifacts.                                                                                | `none`             |                  |
| `LY_RELEASES_URL`   | Override URL for querying ly available remote releases.                                                                                     | `none`             |                  |
| `LY_LISTEN_PORT`    | TCP port on which the ly service listens.                                                                                                   | `8080`             |                  |

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
