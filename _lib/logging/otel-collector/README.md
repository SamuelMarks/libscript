# OpenTelemetry Collector (`_lib/logging/otel-collector/`)

## Overview

Vendor-agnostic proxy receiving, processing, and exporting OpenTelemetry traces, metrics, and logs.

- **Tier**: `T1` (`_lib/logging/otel-collector/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `otel-collector`, `otelcol`, `telemetry`

## Usage

```sh
# Install and manage the otel-collector service daemon
./libscript.sh install otel-collector latest
./libscript.sh start otel-collector
./libscript.sh status otel-collector
./libscript.sh logs otel-collector
./libscript.sh stop otel-collector
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install otel-collector latest
.\libscript.cmd start otel-collector
.\libscript.cmd status otel-collector
.\libscript.cmd stop otel-collector
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/otel-collector/<version>` (default `~/.libscript/otel-collector/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OTEL_COLLECTOR_INSTALL_METHOD` (or global
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

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
