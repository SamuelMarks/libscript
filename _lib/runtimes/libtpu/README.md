# libtpu

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `libtpu` component (part
of `_runtimes`) within the LibScript ecosystem. Isolated version manager and SHA-256 verified
artifact cache for upstream PyPI libtpu wheels (libtpu.so and sdk.so).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Upstream Google libtpu
Reference Wheel & Shared Objects**. It is designed to be executed via the global `libscript.sh`
router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install libtpu
libscript uninstall libtpu
```

**Start / Stop (if configured as a background service):**

```sh
libscript start libtpu
libscript stop libtpu
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker libtpu
```

_Note: On Unix environments, you can also use `./cli.sh install libtpu`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                     | Default            | Aliases/Examples |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIBTPU_INSTALL_METHOD`            | How to install libtpu. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LIBTPU_VERSION`                   | Specific version of libtpu to install.                                                                                                          | `0.0.52`           | latest, lts      |
| `LIBTPU_DOWNLOAD_URL`              | Override URL for downloading libtpu binary or archive artifacts.                                                                                | `none`             |                  |
| `LIBTPU_RELEASES_URL`              | Override URL for querying libtpu available remote releases.                                                                                     | `none`             |                  |
| `LIBTPU_WHEEL_ARCH`                | Wheel architecture(s) to fetch and extract ('x86_64', 'aarch64', or 'both').                                                                    | `both`             |                  |
| `LIBTPU_SO_PATH`                   | Explicit override path to an extracted upstream libtpu.so shared object.                                                                        | `none`             |                  |
| `LIBTPU_SDK_SO_PATH`               | Explicit override path to an extracted upstream sdk.so / sdk.abi3.so shared object.                                                             | `none`             |                  |
| `LIBTPU_REFERENCE_DIR`             | Resolved directory containing extracted upstream libtpu reference wheels and shared objects.                                                    | `none`             |                  |
| `LIBTPU_REFERENCE_SO`              | Resolved path to the active host-matching upstream libtpu.so artifact.                                                                          | `none`             |                  |
| `LIBTPU_REFERENCE_SDK_SO`          | Resolved path to the active host-matching upstream sdk.so artifact.                                                                             | `none`             |                  |
| `LIBTPU_ACTIVATE_TPU_LIBRARY_PATH` | Flag (0 or 1) controlling whether env.sh/env.cmd exports TPU_LIBRARY_PATH pointing at upstream libtpu.so.                                       | `0`                |                  |

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
