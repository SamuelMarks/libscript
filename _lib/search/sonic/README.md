# sonic

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `sonic` component (part of
`_search`) within the LibScript ecosystem. Fast, lightweight, and schema-less search backend written
in Rust as a minimal alternative to heavy search clusters.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Sonic**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install sonic
libscript uninstall sonic
```

**Start / Stop (if configured as a background service):**

```sh
libscript start sonic
libscript stop sonic
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker sonic
```

_Note: On Unix environments, you can also use `./cli.sh install sonic`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SONIC_INSTALL_METHOD` | How to install sonic. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SONIC_VERSION`        | Specific version of sonic to install.                                                                                                          | `latest`           | latest, lts      |
| `SONIC_DOWNLOAD_URL`   | Override URL for downloading sonic binary or archive artifacts.                                                                                | `none`             |                  |
| `SONIC_RELEASES_URL`   | Override URL for querying sonic available remote releases.                                                                                     | `none`             |                  |
| `SONIC_LISTEN_PORT`    | TCP port on which the sonic service listens.                                                                                                   | `1491`             |                  |

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
