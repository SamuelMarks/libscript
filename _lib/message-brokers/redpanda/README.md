# redpanda

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `redpanda` component (part
of `_message-brokers`) within the LibScript ecosystem. C++ Kafka-compatible streaming data platform
and rpk CLI engineered without JVM or ZooKeeper dependencies.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Redpanda**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install redpanda
libscript uninstall redpanda
```

**Start / Stop (if configured as a background service):**

```sh
libscript start redpanda
libscript stop redpanda
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker redpanda
```

_Note: On Unix environments, you can also use `./cli.sh install redpanda`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `REDPANDA_INSTALL_METHOD` | How to install redpanda. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `REDPANDA_VERSION`        | Specific version of redpanda to install.                                                                                                          | `latest`           | latest, lts      |
| `REDPANDA_DOWNLOAD_URL`   | Override URL for downloading redpanda binary or archive artifacts.                                                                                | `none`             |                  |
| `REDPANDA_RELEASES_URL`   | Override URL for querying redpanda available remote releases.                                                                                     | `none`             |                  |
| `REDPANDA_LISTEN_PORT`    | TCP port on which the redpanda service listens.                                                                                                   | `9092`             |                  |

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
