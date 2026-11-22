# automake

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `automake` component (part
of `_toolchains`) within the LibScript ecosystem. Tool for automatically generating GNU
Standards-compliant Makefile.in files.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **GNU Automake**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install automake
libscript uninstall automake
```

**Start / Stop (if configured as a background service):**

```sh
libscript start automake
libscript stop automake
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker automake
```

_Note: On Unix environments, you can also use `./cli.sh install automake`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `AUTOMAKE_INSTALL_METHOD` | How to install automake. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `AUTOMAKE_VERSION`        | Specific version of automake to install.                                                                                                          | `latest` | latest, 1.17     |
| `AUTOMAKE_DOWNLOAD_URL`   | Override URL for downloading automake binary or archive artifacts.                                                                                | `none`   |                  |
| `AUTOMAKE_RELEASES_URL`   | Override URL for querying automake available remote releases.                                                                                     | `none`   |                  |

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
