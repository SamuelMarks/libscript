# ZeroMQ (`_lib/message-brokers/zeromq/`)

## Overview

High-performance asynchronous distributed messaging library (libzmq) and CurveZMQ key generation
tools.

- **Tier**: `T1` (`_lib/message-brokers/zeromq/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `zeromq`, `libzmq`, `zmq`

## Usage

```sh
# Install and manage the zeromq service daemon
./libscript.sh install zeromq latest
./libscript.sh start zeromq
./libscript.sh status zeromq
./libscript.sh logs zeromq
./libscript.sh stop zeromq
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install zeromq latest
.\libscript.cmd start zeromq
.\libscript.cmd status zeromq
.\libscript.cmd stop zeromq
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/zeromq/<version>`
  (default `~/.libscript/zeromq/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ZEROMQ_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `ZEROMQ_INSTALL_METHOD` | How to install zeromq. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `ZEROMQ_VERSION`        | Specific version of zeromq to install.                                                                                                          | `latest` | latest, lts      |
| `ZEROMQ_DOWNLOAD_URL`   | Override URL for downloading zeromq binary or archive artifacts.                                                                                | `none`   |                  |
| `ZEROMQ_RELEASES_URL`   | Override URL for querying zeromq available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
