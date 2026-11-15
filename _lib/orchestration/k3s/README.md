# k3s

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `k3s` component (part of
`_orchestration`) within the LibScript ecosystem. CNCF certified lightweight single-binary
Kubernetes distribution (k3s) built for edge, IoT, CI, and cloud workloads.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Rancher K3s Lightweight
Kubernetes**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install k3s
libscript uninstall k3s
```

**Start / Stop (if configured as a background service):**

```sh
libscript start k3s
libscript stop k3s
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker k3s
```

_Note: On Unix environments, you can also use `./cli.sh install k3s`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `K3S_INSTALL_METHOD` | How to install k3s. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `K3S_VERSION`        | Specific version of k3s to install.                                                                                                          | `latest`           | latest, stable   |
| `K3S_DOWNLOAD_URL`   | Override URL for downloading k3s binary or archive artifacts.                                                                                | `none`             |                  |
| `K3S_RELEASES_URL`   | Override URL for querying k3s available remote releases.                                                                                     | `none`             |                  |
| `K3S_LISTEN_PORT`    | TCP port on which the k3s service listens.                                                                                                   | `6443`             |                  |

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
