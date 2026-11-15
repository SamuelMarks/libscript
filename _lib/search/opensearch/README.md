# opensearch

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `opensearch` component
(part of `_search`) within the LibScript ecosystem. Community-driven Apache 2.0 distributed search,
analytics, and vector database suite.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OpenSearch**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install opensearch
libscript uninstall opensearch
```

**Start / Stop (if configured as a background service):**

```sh
libscript start opensearch
libscript stop opensearch
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker opensearch
```

_Note: On Unix environments, you can also use `./cli.sh install opensearch`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OPENSEARCH_INSTALL_METHOD` | How to install opensearch. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OPENSEARCH_VERSION`        | Specific version of opensearch to install.                                                                                                          | `latest`           | latest, lts      |
| `OPENSEARCH_DOWNLOAD_URL`   | Override URL for downloading opensearch binary or archive artifacts.                                                                                | `none`             |                  |
| `OPENSEARCH_RELEASES_URL`   | Override URL for querying opensearch available remote releases.                                                                                     | `none`             |                  |
| `OPENSEARCH_LISTEN_PORT`    | TCP port on which the opensearch service listens.                                                                                                   | `9200`             |                  |

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
