# Grafana (`_lib/logging/grafana/`)

## Overview

Open-source analytics, interactive visualization, and alerting web platform for metrics, logs, and
traces.

- **Tier**: `T1` (`_lib/logging/grafana/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `grafana`, `dashboards`, `observability`

## Usage

```sh
# Install and manage the grafana service daemon
./libscript.sh install grafana latest
./libscript.sh start grafana
./libscript.sh status grafana
./libscript.sh logs grafana
./libscript.sh stop grafana
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install grafana latest
.\libscript.cmd start grafana
.\libscript.cmd status grafana
.\libscript.cmd stop grafana
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/grafana/<version>`
  (default `~/.libscript/grafana/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GRAFANA_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `backup_tenant.{sh,cmd}`,
`configure.{sh,cmd}`, `deprovision_tenant.{sh,cmd}`, `log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`,
`metrics.{sh,cmd}`, `probe.{sh,cmd}`, `provision_tenant.{sh,cmd}`, `restore.{sh,cmd}`,
`restore_tenant.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `GRAFANA_INSTALL_METHOD` | How to install grafana. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GRAFANA_VERSION`        | Specific version of grafana to install.                                                                                                          | `latest`           | latest, lts      |
| `GRAFANA_DOWNLOAD_URL`   | Override URL for downloading grafana binary or archive artifacts.                                                                                | `none`             |                  |
| `GRAFANA_RELEASES_URL`   | Override URL for querying grafana available remote releases.                                                                                     | `none`             |                  |
| `GRAFANA_LISTEN_PORT`    | TCP port on which the grafana service listens.                                                                                                   | `3000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
