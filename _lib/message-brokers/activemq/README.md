# activemq

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `activemq` component (part
of `_message-brokers`) within the LibScript ecosystem. Multi-protocol Java message broker supporting
JMS, AMQP, STOMP, MQTT, and OpenWire.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Apache ActiveMQ**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install activemq
libscript uninstall activemq
```

**Start / Stop (if configured as a background service):**

```sh
libscript start activemq
libscript stop activemq
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker activemq
```

_Note: On Unix environments, you can also use `./cli.sh install activemq`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ACTIVEMQ_INSTALL_METHOD` | How to install activemq. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `ACTIVEMQ_VERSION`        | Specific version of activemq to install.                                                                                                          | `latest`           | latest, lts      |
| `ACTIVEMQ_DOWNLOAD_URL`   | Override URL for downloading activemq binary or archive artifacts.                                                                                | `none`             |                  |
| `ACTIVEMQ_RELEASES_URL`   | Override URL for querying activemq available remote releases.                                                                                     | `none`             |                  |
| `ACTIVEMQ_LISTEN_PORT`    | TCP port on which the activemq service listens.                                                                                                   | `61616`            |                  |

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
