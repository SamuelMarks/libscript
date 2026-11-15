# grafana

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `grafana` component (part
of `_logging`) within the LibScript ecosystem. Open-source analytics, interactive visualization, and
alerting web platform for metrics, logs, and traces.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Grafana**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install grafana
libscript uninstall grafana
```

**Start / Stop (if configured as a background service):**

```sh
libscript start grafana
libscript stop grafana
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker grafana
```

_Note: On Unix environments, you can also use `./cli.sh install grafana`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `GRAFANA_INSTALL_METHOD` | How to install grafana. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GRAFANA_VERSION`        | Specific version of grafana to install.                                                                                                          | `latest`           | latest, lts      |
| `GRAFANA_DOWNLOAD_URL`   | Override URL for downloading grafana binary or archive artifacts.                                                                                | `none`             |                  |
| `GRAFANA_RELEASES_URL`   | Override URL for querying grafana available remote releases.                                                                                     | `none`             |                  |
| `GRAFANA_LISTEN_PORT`    | TCP port on which the grafana service listens.                                                                                                   | `3000`             |                  |

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
