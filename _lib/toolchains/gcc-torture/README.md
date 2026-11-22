# gcc-torture

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `gcc-torture` component
(part of `_toolchains`) within the LibScript ecosystem. Standalone version manager for the upstream
GCC gcc.c-torture/execute C execution test corpus with DejaGnu .x and nested-function filter
manifests.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Upstream GCC C Torture
Execute Conformance Suite**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install gcc-torture
libscript uninstall gcc-torture
```

**Start / Stop (if configured as a background service):**

```sh
libscript start gcc-torture
libscript stop gcc-torture
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker gcc-torture
```

_Note: On Unix environments, you can also use `./cli.sh install gcc-torture`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                            | Description                                                                                                                                          | Default            | Aliases/Examples |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GCC_TORTURE_INSTALL_METHOD`        | How to install gcc-torture. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GCC_TORTURE_VERSION`               | Specific version of gcc-torture to install.                                                                                                          | `14.2.0`           | latest, lts      |
| `GCC_TORTURE_DOWNLOAD_URL`          | Override URL for downloading gcc-torture binary or archive artifacts.                                                                                | `none`             |                  |
| `GCC_TORTURE_RELEASES_URL`          | Override URL for querying gcc-torture available remote releases.                                                                                     | `none`             |                  |
| `GCC_TORTURE_DIR`                   | Filesystem directory containing extracted gcc.c-torture/execute/*.c test cases.                                                                      | `none`             |                  |
| `GCC_TORTURE_SKIP_NESTED_FUNCTIONS` | Whether tests relying on non-standard GNU nested functions or DejaGnu target-skip .x directives are filtered out.                                    | `true`             |                  |

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
