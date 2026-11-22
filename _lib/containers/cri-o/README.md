# cri-o

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `cri-o` component (part of
`_orchestration`) within the LibScript ecosystem. Lightweight OCI-based implementation of the
Kubernetes Container Runtime Interface (crio).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **CRI-O Kubernetes Container
Runtime**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install cri-o
libscript uninstall cri-o
```

**Start / Stop (if configured as a background service):**

```sh
libscript start cri-o
libscript stop cri-o
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker cri-o
```

_Note: On Unix environments, you can also use `./cli.sh install cri-o`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CRI_O_INSTALL_METHOD` | How to install cri-o. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CRI_O_VERSION`        | Specific version of cri-o to install.                                                                                                          | `latest`           | latest, stable   |
| `CRI_O_DOWNLOAD_URL`   | Override URL for downloading cri-o binary or archive artifacts.                                                                                | `none`             |                  |
| `CRI_O_RELEASES_URL`   | Override URL for querying cri-o available remote releases.                                                                                     | `none`             |                  |
| `CRI_O_LISTEN_PORT`    | TCP port on which the cri-o service listens.                                                                                                   | `8080`             |                  |

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
