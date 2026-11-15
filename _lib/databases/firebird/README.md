# firebird

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `firebird` component (part
of `_databases`) within the LibScript ecosystem. Open-source relational SQL database management
system offering ANSI SQL standard compliance and stored procedures.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Firebird SQL**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install firebird
libscript uninstall firebird
```

**Start / Stop (if configured as a background service):**

```sh
libscript start firebird
libscript stop firebird
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker firebird
```

_Note: On Unix environments, you can also use `./cli.sh install firebird`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `FIREBIRD_INSTALL_METHOD` | How to install firebird. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `FIREBIRD_VERSION`        | Specific version of firebird to install.                                                                                                          | `latest` | latest, lts      |
| `FIREBIRD_DOWNLOAD_URL`   | Override URL for downloading firebird binary or archive artifacts.                                                                                | `none`   |                  |
| `FIREBIRD_RELEASES_URL`   | Override URL for querying firebird available remote releases.                                                                                     | `none`   |                  |
| `FIREBIRD_LISTEN_PORT`    | TCP port on which the firebird service listens.                                                                                                   | `3050`   |                  |

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
