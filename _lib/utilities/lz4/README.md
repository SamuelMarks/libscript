# lz4

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `lz4` component (part of
`_utilities`) within the LibScript ecosystem. Standalone version manager and custom-compiler source
builder for LZ4 (pinned default 1.10.0) with upstream make check/test verification.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **LZ4 Lossless Compression
Library & CLI**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install lz4
libscript uninstall lz4
```

**Start / Stop (if configured as a background service):**

```sh
libscript start lz4
libscript stop lz4
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker lz4
```

_Note: On Unix environments, you can also use `./cli.sh install lz4`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default       | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `LZ4_INSTALL_METHOD` | How to install lz4. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `LZ4_VERSION`        | Specific version of lz4 to install.                                                                                                          | `1.10.0`      | latest, lts      |
| `LZ4_DOWNLOAD_URL`   | Override URL for downloading lz4 binary or archive artifacts.                                                                                | `none`        |                  |
| `LZ4_RELEASES_URL`   | Override URL for querying lz4 available remote releases.                                                                                     | `none`        |                  |
| `LZ4_RUN_TESTS`      | Whether to execute the upstream LZ4 test suite (make check) after building from source.                                                      | `none`        |                  |

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
