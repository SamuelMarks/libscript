# containerd

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `containerd` component
(part of `_orchestration`) within the LibScript ecosystem. Industry-standard CNCF graduated core
container runtime daemon (containerd, ctr, containerd-shim-runc-v2).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **containerd Container
Runtime**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install containerd
libscript uninstall containerd
```

**Start / Stop (if configured as a background service):**

```sh
libscript start containerd
libscript stop containerd
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker containerd
```

_Note: On Unix environments, you can also use `./cli.sh install containerd`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CONTAINERD_INSTALL_METHOD` | How to install containerd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CONTAINERD_VERSION`        | Specific version of containerd to install.                                                                                                          | `latest`           | latest, stable   |
| `CONTAINERD_DOWNLOAD_URL`   | Override URL for downloading containerd binary or archive artifacts.                                                                                | `none`             |                  |
| `CONTAINERD_RELEASES_URL`   | Override URL for querying containerd available remote releases.                                                                                     | `none`             |                  |
| `CONTAINERD_LISTEN_PORT`    | TCP port on which the containerd service listens.                                                                                                   | `8080`             |                  |

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
