# rancher

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `rancher` component (part
of `_orchestration`) within the LibScript ecosystem. Rancher multi-cluster Kubernetes management CLI
and control-plane server orchestration recipe.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Rancher Multi-Cluster
Kubernetes Manager**. It is designed to be executed via the global `libscript.sh` router or directly
via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install rancher
libscript uninstall rancher
```

**Start / Stop (if configured as a background service):**

```sh
libscript start rancher
libscript stop rancher
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker rancher
```

_Note: On Unix environments, you can also use `./cli.sh install rancher`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `RANCHER_INSTALL_METHOD` | How to install rancher. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `RANCHER_VERSION`        | Specific version of rancher to install.                                                                                                          | `latest`           | latest, stable   |
| `RANCHER_DOWNLOAD_URL`   | Override URL for downloading rancher binary or archive artifacts.                                                                                | `none`             |                  |
| `RANCHER_RELEASES_URL`   | Override URL for querying rancher available remote releases.                                                                                     | `none`             |                  |
| `RANCHER_LISTEN_PORT`    | TCP port on which the rancher service listens.                                                                                                   | `80`               |                  |

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
