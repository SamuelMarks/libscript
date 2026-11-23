# OpenSearch Dashboards (`_lib/search/opensearch-dashboards/`)

## Overview

Open-source data visualization, search analytics, and observability UI dashboard server for
OpenSearch.

- **Tier**: `T1` (`_lib/search/opensearch-dashboards/`)
- **Capabilities**: `userland-package`, `service-daemon`

## Usage

```sh
# Install and manage the opensearch-dashboards service daemon
./libscript.sh install opensearch-dashboards latest
./libscript.sh start opensearch-dashboards
./libscript.sh status opensearch-dashboards
./libscript.sh logs opensearch-dashboards
./libscript.sh stop opensearch-dashboards
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install opensearch-dashboards latest
.\libscript.cmd start opensearch-dashboards
.\libscript.cmd status opensearch-dashboards
.\libscript.cmd stop opensearch-dashboards
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/opensearch-dashboards/<version>` (default
  `~/.libscript/opensearch-dashboards/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OPENSEARCH_DASHBOARDS_INSTALL_METHOD` (or global
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

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
