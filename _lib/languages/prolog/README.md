# prolog

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `prolog` component (part
of `_languages`) within the LibScript ecosystem. Comprehensive SWI-Prolog (swipl) logic programming
environment and compiler.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **SWI-Prolog**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install prolog
libscript uninstall prolog
```

**Start / Stop (if configured as a background service):**

```sh
libscript start prolog
libscript stop prolog
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker prolog
```

_Note: On Unix environments, you can also use `./cli.sh install prolog`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PROLOG_INSTALL_METHOD` | How to install prolog. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `PROLOG_VERSION`        | Specific version of prolog to install.                                                                                                          | `latest` | latest, lts      |
| `PROLOG_DOWNLOAD_URL`   | Override URL for downloading prolog binary or archive artifacts.                                                                                | `none`   |                  |
| `PROLOG_RELEASES_URL`   | Override URL for querying prolog available remote releases.                                                                                     | `none`   |                  |

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
