# Fluent Bit (`_lib/logging/fluentbit/`)

## Overview

A super fast, lightweight, and highly scalable logging and metrics processor and forwarder.

- **Tier**: `T1` (`_lib/logging/fluentbit/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `fluentbit`, `logging`, `metrics`, `server`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the fluentbit service daemon
./libscript.sh install fluentbit latest
./libscript.sh start fluentbit
./libscript.sh status fluentbit
./libscript.sh logs fluentbit
./libscript.sh stop fluentbit
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install fluentbit latest
.\libscript.cmd start fluentbit
.\libscript.cmd status fluentbit
.\libscript.cmd stop fluentbit
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/fluentbit/<version>`
  (default `~/.libscript/fluentbit/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `FLUENTBIT_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                            | Description                                                                                                                                                 | Default               | Aliases/Examples |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ---------------- |
| `FLUENTBIT_VERSION`                 | Specific version of Fluent Bit to install. Can be a numeric version (e.g. '3.0.0') or an alias like 'latest'.                                               | `latest`              | latest, stable   |
| `FLUENTBIT_INSTALL_METHOD`          | Installation strategy for fluentbit: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native`    |                  |
| `FLUENTBIT_CONFIG_FILE`             | Absolute path to a pre-existing custom fluent-bit.conf file to use instead of the default configuration.                                                    | `none`                |                  |
| `FLUENTBIT_LOG_LEVEL`               | The logging verbosity level for the Fluent Bit daemon itself (e.g. info, debug, error).                                                                     | `info`                |                  |
| `FLUENTBIT_HTTP_SERVER`             | Enable the built-in HTTP server for metrics and health checks. Highly recommended for monitoring.                                                           | `On`                  |                  |
| `FLUENTBIT_LISTEN_PORT`             | Port for the Fluent Bit HTTP metrics interface to listen on.                                                                                                | `2020`                |                  |
| `FLUENTBIT_LISTEN_ADDRESS`          | Address for the Fluent Bit HTTP metrics interface to bind to.                                                                                               | `0.0.0.0`             |                  |
| `FLUENTBIT_LISTEN_SOCKET`           | Optional: Unix socket for the Fluent Bit metrics interface to listen on (Linux/macOS only).                                                                 | `none`                |                  |
| `FLUENTBIT_DEFAULT_INPUT`           | Default input plugin to configure for collecting data (e.g. 'tail', 'forward', 'cpu', 'dummy').                                                             | `dummy`               |                  |
| `FLUENTBIT_DEFAULT_OUTPUT`          | Default output plugin to configure for routing data (e.g. 'stdout', 'es', 'loki', 'http').                                                                  | `stdout`              |                  |
| `FLUENTBIT_SERVICE_RUN_AS_USER`     | Windows local user account to run the service under (leave empty to use Network Service / Local System).                                                    | `none`                |                  |
| `FLUENTBIT_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable).                                                                                                | `none`                |                  |
| `FLUENTBIT_SERVICE_NAME`            | Custom name for the Fluent Bit background service (allows side-by-side installations).                                                                      | `libscript_fluentbit` |                  |
| `FLUENTBIT_DOWNLOAD_URL`            | Override URL for downloading fluentbit binary or archive artifacts.                                                                                         | `none`                |                  |
| `FLUENTBIT_RELEASES_URL`            | Override URL for querying fluentbit available remote releases.                                                                                              | `none`                |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
