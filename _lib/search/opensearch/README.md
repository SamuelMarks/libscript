# OpenSearch (`_lib/search/opensearch/`)

## Overview

Community-driven Apache 2.0 distributed search, analytics, and vector database suite.

- **Tier**: `T1` (`_lib/search/opensearch/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `opensearch`, `search`

## Usage

```sh
# Install and manage the opensearch service daemon
./libscript.sh install opensearch latest
./libscript.sh start opensearch
./libscript.sh status opensearch
./libscript.sh logs opensearch
./libscript.sh stop opensearch
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install opensearch latest
.\libscript.cmd start opensearch
.\libscript.cmd status opensearch
.\libscript.cmd stop opensearch
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/opensearch/<version>`
  (default `~/.libscript/opensearch/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OPENSEARCH_INSTALL_METHOD` (or global
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

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OPENSEARCH_INSTALL_METHOD` | How to install opensearch. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OPENSEARCH_VERSION`        | Specific version of opensearch to install.                                                                                                          | `latest`           | latest, lts      |
| `OPENSEARCH_DOWNLOAD_URL`   | Override URL for downloading opensearch binary or archive artifacts.                                                                                | `none`             |                  |
| `OPENSEARCH_RELEASES_URL`   | Override URL for querying opensearch available remote releases.                                                                                     | `none`             |                  |
| `OPENSEARCH_LISTEN_PORT`    | TCP port on which the opensearch service listens.                                                                                                   | `9200`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
