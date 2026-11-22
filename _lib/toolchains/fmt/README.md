# fmt

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `fmt` component (part of
`_toolchains`) within the LibScript ecosystem. Standalone version manager and CMake source builder
for {fmt} (pinned default 11.0.2), providing both single-TU fmt/format.cc template inputs and full
multi-TU CTest verification.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **{fmt} Modern C++17
Formatting Library**. It is designed to be executed via the global `libscript.sh` router or directly
via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install fmt
libscript uninstall fmt
```

**Start / Stop (if configured as a background service):**

```sh
libscript start fmt
libscript stop fmt
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker fmt
```

_Note: On Unix environments, you can also use `./cli.sh install fmt`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default       | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `FMT_INSTALL_METHOD` | How to install fmt. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `FMT_VERSION`        | Specific version of fmt to install.                                                                                                          | `11.0.2`      | latest, lts      |
| `FMT_DOWNLOAD_URL`   | Override URL for downloading fmt binary or archive artifacts.                                                                                | `none`        |                  |
| `FMT_RELEASES_URL`   | Override URL for querying fmt available remote releases.                                                                                     | `none`        |                  |
| `FMT_RUN_TESTS`      | Whether to build and execute the upstream {fmt} CTest suite during source builds.                                                            | `none`        |                  |
| `FMT_SOURCE_DIR`     | Extracted {fmt} source directory containing include/fmt/format-inl.h and src/format.cc for single-TU benchmarks.                             | `none`        |                  |

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
