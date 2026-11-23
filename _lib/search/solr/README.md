# Apache Solr (`_lib/search/solr/`)

## Overview

Open-source enterprise-grade search platform built on Apache Lucene with SolrCloud clustering.

- **Tier**: `T1` (`_lib/search/solr/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `solr`, `search`

## Usage

```sh
# Install and manage the solr service daemon
./libscript.sh install solr latest
./libscript.sh start solr
./libscript.sh status solr
./libscript.sh logs solr
./libscript.sh stop solr
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install solr latest
.\libscript.cmd start solr
.\libscript.cmd status solr
.\libscript.cmd stop solr
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/solr/<version>`
  (default `~/.libscript/solr/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SOLR_INSTALL_METHOD` (or global
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

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SOLR_INSTALL_METHOD` | How to install solr. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SOLR_VERSION`        | Specific version of solr to install.                                                                                                          | `latest`           | latest, lts      |
| `SOLR_DOWNLOAD_URL`   | Override URL for downloading solr binary or archive artifacts.                                                                                | `none`             |                  |
| `SOLR_RELEASES_URL`   | Override URL for querying solr available remote releases.                                                                                     | `none`             |                  |
| `SOLR_LISTEN_PORT`    | TCP port on which the solr service listens.                                                                                                   | `8983`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
