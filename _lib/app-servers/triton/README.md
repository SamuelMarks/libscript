# triton

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `triton` component (part
of `_app-servers`) within the LibScript ecosystem. Open-source inference serving software
streamlining AI model deployment across GPUs and CPUs.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **NVIDIA Triton Inference
Server**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install triton
libscript uninstall triton
```

**Start / Stop (if configured as a background service):**

```sh
libscript start triton
libscript stop triton
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker triton
```

_Note: On Unix environments, you can also use `./cli.sh install triton`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TRITON_INSTALL_METHOD` | How to install triton. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TRITON_VERSION`        | Specific version of triton to install.                                                                                                          | `latest`           | latest, lts      |
| `TRITON_DOWNLOAD_URL`   | Override URL for downloading triton binary or archive artifacts.                                                                                | `none`             |                  |
| `TRITON_RELEASES_URL`   | Override URL for querying triton available remote releases.                                                                                     | `none`             |                  |
| `TRITON_LISTEN_PORT`    | TCP port on which the triton service listens.                                                                                                   | `8000`             |                  |

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
