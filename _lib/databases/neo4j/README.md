# Neo4j (`_lib/databases/neo4j/`)

## Overview

High-performance native graph database platform for connected data and Cypher query workloads.

- **Tier**: `T1` (`_lib/databases/neo4j/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `neo4j`, `graph-database`, `database`

## Usage

```sh
# Install and manage the neo4j service daemon
./libscript.sh install neo4j latest
./libscript.sh start neo4j
./libscript.sh status neo4j
./libscript.sh logs neo4j
./libscript.sh stop neo4j
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install neo4j latest
.\libscript.cmd start neo4j
.\libscript.cmd status neo4j
.\libscript.cmd stop neo4j
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/neo4j/<version>`
  (default `~/.libscript/neo4j/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `NEO4J_INSTALL_METHOD` (or global
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

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NEO4J_INSTALL_METHOD` | How to install neo4j. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `NEO4J_VERSION`        | Specific version of neo4j to install.                                                                                                          | `latest`           | latest, lts      |
| `NEO4J_DOWNLOAD_URL`   | Override URL for downloading neo4j binary or archive artifacts.                                                                                | `none`             |                  |
| `NEO4J_RELEASES_URL`   | Override URL for querying neo4j available remote releases.                                                                                     | `none`             |                  |
| `NEO4J_LISTEN_PORT`    | TCP port on which the neo4j service listens.                                                                                                   | `7474`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
