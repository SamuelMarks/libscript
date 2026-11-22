# gleam

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `gleam` component (part of
`_languages`) within the LibScript ecosystem. Friendly type-safe functional language for building
scalable systems on BEAM and JavaScript.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Gleam**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install gleam
libscript uninstall gleam
```

**Start / Stop (if configured as a background service):**

```sh
libscript start gleam
libscript stop gleam
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker gleam
```

_Note: On Unix environments, you can also use `./cli.sh install gleam`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GLEAM_INSTALL_METHOD` | How to install gleam. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GLEAM_VERSION`        | Specific version of gleam to install.                                                                                                          | `latest`           | latest, lts      |
| `GLEAM_DOWNLOAD_URL`   | Override URL for downloading gleam binary or archive artifacts.                                                                                | `none`             |                  |
| `GLEAM_RELEASES_URL`   | Override URL for querying gleam available remote releases.                                                                                     | `none`             |                  |

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
