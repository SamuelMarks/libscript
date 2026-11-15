# prometheus

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `prometheus` component
(part of `_logging`) within the LibScript ecosystem. Cloud-native dimensional time-series monitoring
server, PromQL query engine, and alerting toolkit.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Prometheus**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install prometheus
libscript uninstall prometheus
```

**Start / Stop (if configured as a background service):**

```sh
libscript start prometheus
libscript stop prometheus
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker prometheus
```

_Note: On Unix environments, you can also use `./cli.sh install prometheus`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PROMETHEUS_INSTALL_METHOD` | How to install prometheus. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PROMETHEUS_VERSION`        | Specific version of prometheus to install.                                                                                                          | `latest`           | latest, lts      |
| `PROMETHEUS_DOWNLOAD_URL`   | Override URL for downloading prometheus binary or archive artifacts.                                                                                | `none`             |                  |
| `PROMETHEUS_RELEASES_URL`   | Override URL for querying prometheus available remote releases.                                                                                     | `none`             |                  |
| `PROMETHEUS_LISTEN_PORT`    | TCP port on which the prometheus service listens.                                                                                                   | `9090`             |                  |

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
