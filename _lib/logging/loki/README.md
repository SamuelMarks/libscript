# loki

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `loki` component (part of
`_logging`) within the LibScript ecosystem. Horizontally scalable, highly available, multi-tenant
log aggregation system inspired by Prometheus.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Grafana Loki**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install loki
libscript uninstall loki
```

**Start / Stop (if configured as a background service):**

```sh
libscript start loki
libscript stop loki
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker loki
```

_Note: On Unix environments, you can also use `./cli.sh install loki`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LOKI_INSTALL_METHOD` | How to install loki. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LOKI_VERSION`        | Specific version of loki to install.                                                                                                          | `latest`           | latest, lts      |
| `LOKI_DOWNLOAD_URL`   | Override URL for downloading loki binary or archive artifacts.                                                                                | `none`             |                  |
| `LOKI_RELEASES_URL`   | Override URL for querying loki available remote releases.                                                                                     | `none`             |                  |
| `LOKI_LISTEN_PORT`    | TCP port on which the loki service listens.                                                                                                   | `3100`             |                  |

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
