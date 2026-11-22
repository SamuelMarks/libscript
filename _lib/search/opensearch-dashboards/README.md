# opensearch-dashboards

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `opensearch-dashboards`
component (part of `_orchestration`) within the LibScript ecosystem. Open-source data visualization,
search analytics, and observability UI dashboard server for OpenSearch.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OpenSearch Dashboards**. It
is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install opensearch-dashboards
libscript uninstall opensearch-dashboards
```

**Start / Stop (if configured as a background service):**

```sh
libscript start opensearch-dashboards
libscript stop opensearch-dashboards
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker opensearch-dashboards
```

_Note: On Unix environments, you can also use `./cli.sh install opensearch-dashboards`. On Windows,
use `libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                                                                    | Default            | Aliases/Examples |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OPENSEARCH_DASHBOARDS_INSTALL_METHOD` | How to install opensearch-dashboards. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OPENSEARCH_DASHBOARDS_VERSION`        | Specific version of opensearch-dashboards to install.                                                                                                          | `latest`           | latest, stable   |
| `OPENSEARCH_DASHBOARDS_DOWNLOAD_URL`   | Override URL for downloading opensearch-dashboards binary or archive artifacts.                                                                                | `none`             |                  |
| `OPENSEARCH_DASHBOARDS_RELEASES_URL`   | Override URL for querying opensearch-dashboards available remote releases.                                                                                     | `none`             |                  |
| `OPENSEARCH_DASHBOARDS_LISTEN_PORT`    | TCP port on which the opensearch-dashboards service listens.                                                                                                   | `5601`             |                  |

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
