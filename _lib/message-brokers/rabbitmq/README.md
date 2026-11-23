# RabbitMQ (`_lib/message-brokers/rabbitmq/`)

## Overview

The most widely deployed open source message broker.

- **Tier**: `T1` (`_lib/message-brokers/rabbitmq/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `message-broker`, `rabbitmq`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the rabbitmq service daemon
./libscript.sh install rabbitmq latest
./libscript.sh start rabbitmq
./libscript.sh status rabbitmq
./libscript.sh logs rabbitmq
./libscript.sh stop rabbitmq
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install rabbitmq latest
.\libscript.cmd start rabbitmq
.\libscript.cmd status rabbitmq
.\libscript.cmd stop rabbitmq
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/rabbitmq/<version>`
  (default `~/.libscript/rabbitmq/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `RABBITMQ_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                                | Default            | Aliases/Examples |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RABBITMQ_LISTEN_ADDRESS` | Address for RabbitMQ to listen on.                                                                                                                         | `none`             |                  |
| `RABBITMQ_LISTEN_PORT`    | Port for RabbitMQ to listen on.                                                                                                                            | `none`             |                  |
| `RABBITMQ_LISTEN_SOCKET`  | UNIX socket path for RabbitMQ to listen on.                                                                                                                | `none`             |                  |
| `RABBITMQ_VERSION`        | Version of RabbitMQ to install                                                                                                                             | `latest`           |                  |
| `RABBITMQ_INSTALL_METHOD` | Installation strategy for rabbitmq: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `RABBITMQ_DOWNLOAD_URL`   | Override URL for downloading rabbitmq binary or archive artifacts.                                                                                         | `none`             |                  |
| `RABBITMQ_LISTEN`         | Listen endpoint (address:port or socket) for rabbitmq.                                                                                                     | `none`             |                  |
| `RABBITMQ_RELEASES_URL`   | Override URL for querying rabbitmq available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
