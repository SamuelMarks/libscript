# yarpgen

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `yarpgen` component (part
of `_toolchains`) within the LibScript ecosystem. Standalone version manager and source builder for
YARPGen v2, generating deterministic UB-free C and C++17 differential checksum programs.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **YARPGen v2 Random C/C++17
Optimizer Fuzzing Generator**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install yarpgen
libscript uninstall yarpgen
```

**Start / Stop (if configured as a background service):**

```sh
libscript start yarpgen
libscript stop yarpgen
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker yarpgen
```

_Note: On Unix environments, you can also use `./cli.sh install yarpgen`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default       | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | ---------------- |
| `YARPGEN_INSTALL_METHOD` | How to install yarpgen. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `YARPGEN_VERSION`        | Specific version of yarpgen to install.                                                                                                          | `2.0`         | latest, lts      |
| `YARPGEN_DOWNLOAD_URL`   | Override URL for downloading yarpgen binary or archive artifacts.                                                                                | `none`        |                  |
| `YARPGEN_RELEASES_URL`   | Override URL for querying yarpgen available remote releases.                                                                                     | `none`        |                  |

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
