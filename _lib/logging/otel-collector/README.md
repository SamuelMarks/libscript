# otel-collector

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `otel-collector` component
(part of `_logging`) within the LibScript ecosystem. Vendor-agnostic proxy receiving, processing,
and exporting OpenTelemetry traces, metrics, and logs.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OpenTelemetry Collector**.
It is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install otel-collector
libscript uninstall otel-collector
```

**Start / Stop (if configured as a background service):**

```sh
libscript start otel-collector
libscript stop otel-collector
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker otel-collector
```

_Note: On Unix environments, you can also use `./cli.sh install otel-collector`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                             | Default            | Aliases/Examples |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OTEL_COLLECTOR_INSTALL_METHOD` | How to install otel-collector. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OTEL_COLLECTOR_VERSION`        | Specific version of otel-collector to install.                                                                                                          | `latest`           | latest, lts      |
| `OTEL_COLLECTOR_DOWNLOAD_URL`   | Override URL for downloading otel-collector binary or archive artifacts.                                                                                | `none`             |                  |
| `OTEL_COLLECTOR_RELEASES_URL`   | Override URL for querying otel-collector available remote releases.                                                                                     | `none`             |                  |
| `OTEL_COLLECTOR_LISTEN_PORT`    | TCP port on which the otel-collector service listens.                                                                                                   | `4317`             |                  |

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
