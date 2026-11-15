# bear

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `bear` component (part of
`_toolchains`) within the LibScript ecosystem. Standalone version manager and installer for Build
EAR (bear), generating Clang JSON compilation databases (compile_commands.json) for Make and Kbuild
projects.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Bear Compilation Database
Generator (compile_commands.json)**. It is designed to be executed via the global `libscript.sh`
router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install bear
libscript uninstall bear
```

**Start / Stop (if configured as a background service):**

```sh
libscript start bear
libscript stop bear
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker bear
```

_Note: On Unix environments, you can also use `./cli.sh install bear`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `BEAR_INSTALL_METHOD` | How to install bear. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `BEAR_VERSION`        | Specific version of bear to install.                                                                                                          | `3.1.5`  | latest, lts      |
| `BEAR_DOWNLOAD_URL`   | Override URL for downloading bear binary or archive artifacts.                                                                                | `none`   |                  |
| `BEAR_RELEASES_URL`   | Override URL for querying bear available remote releases.                                                                                     | `none`   |                  |

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
