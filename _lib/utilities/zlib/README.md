# zlib

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `zlib` component (part of
`_utilities`) within the LibScript ecosystem. Standalone version manager and custom-compiler source
builder for zlib (pinned default 1.3.1) with upstream make test / CTest verification.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **zlib Compression Library**.
It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install zlib
libscript uninstall zlib
```

**Start / Stop (if configured as a background service):**

```sh
libscript start zlib
libscript stop zlib
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker zlib
```

_Note: On Unix environments, you can also use `./cli.sh install zlib`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default       | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `ZLIB_INSTALL_METHOD` | How to install zlib. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `ZLIB_VERSION`        | Specific version of zlib to install.                                                                                                          | `1.3.1`       | latest, lts      |
| `ZLIB_DOWNLOAD_URL`   | Override URL for downloading zlib binary or archive artifacts.                                                                                | `none`        |                  |
| `ZLIB_RELEASES_URL`   | Override URL for querying zlib available remote releases.                                                                                     | `none`        |                  |
| `ZLIB_RUN_TESTS`      | Whether to execute upstream zlib make test / ctest checks after building from source.                                                         | `none`        |                  |

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
