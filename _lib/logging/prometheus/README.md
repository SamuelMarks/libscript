# Prometheus (`_lib/logging/prometheus/`)

## Overview

Cloud-native dimensional time-series monitoring server, PromQL query engine, and alerting toolkit.

- **Tier**: `T1` (`_lib/logging/prometheus/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `prometheus`, `metrics-server`, `observability`

## Usage

```sh
# Install and manage the prometheus service daemon
./libscript.sh install prometheus latest
./libscript.sh start prometheus
./libscript.sh status prometheus
./libscript.sh logs prometheus
./libscript.sh stop prometheus
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install prometheus latest
.\libscript.cmd start prometheus
.\libscript.cmd status prometheus
.\libscript.cmd stop prometheus
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/prometheus/<version>`
  (default `~/.libscript/prometheus/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `PROMETHEUS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PROMETHEUS_INSTALL_METHOD` | How to install prometheus. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PROMETHEUS_VERSION`        | Specific version of prometheus to install.                                                                                                          | `latest`           | latest, lts      |
| `PROMETHEUS_DOWNLOAD_URL`   | Override URL for downloading prometheus binary or archive artifacts.                                                                                | `none`             |                  |
| `PROMETHEUS_RELEASES_URL`   | Override URL for querying prometheus available remote releases.                                                                                     | `none`             |                  |
| `PROMETHEUS_LISTEN_PORT`    | TCP port on which the prometheus service listens.                                                                                                   | `9090`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
