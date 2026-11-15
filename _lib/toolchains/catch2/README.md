# catch2

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `catch2` component (part
of `_toolchains`) within the LibScript ecosystem. Standalone version manager and CMake multi-TU
source builder for Catch2 (pinned default 3.7.1) with upstream CTest verification.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Catch2 v3 C++17 Unit
Testing Framework**. It is designed to be executed via the global `libscript.sh` router or directly
via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install catch2
libscript uninstall catch2
```

**Start / Stop (if configured as a background service):**

```sh
libscript start catch2
libscript stop catch2
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker catch2
```

_Note: On Unix environments, you can also use `./cli.sh install catch2`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default       | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `CATCH2_INSTALL_METHOD` | How to install catch2. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `CATCH2_VERSION`        | Specific version of catch2 to install.                                                                                                          | `3.7.1`       | latest, lts      |
| `CATCH2_DOWNLOAD_URL`   | Override URL for downloading catch2 binary or archive artifacts.                                                                                | `none`        |                  |
| `CATCH2_RELEASES_URL`   | Override URL for querying catch2 available remote releases.                                                                                     | `none`        |                  |
| `CATCH2_RUN_TESTS`      | Whether to build and execute Catch2's SelfTest CTest suite during source compilation.                                                           | `none`        |                  |

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
