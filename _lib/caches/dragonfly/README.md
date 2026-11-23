# Dragonfly (`_lib/caches/dragonfly/`)

## Overview

Modern shared-nothing multithreaded in-memory data store compatible with Redis and Memcached
protocols.

- **Tier**: `T1` (`_lib/caches/dragonfly/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `dragonfly`, `redis-compatible`, `kv-store`, `cache`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `sunos`

## Usage

```sh
# Install and manage the dragonfly service daemon
./libscript.sh install dragonfly latest
./libscript.sh start dragonfly
./libscript.sh status dragonfly
./libscript.sh logs dragonfly
./libscript.sh stop dragonfly
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install dragonfly latest
.\libscript.cmd start dragonfly
.\libscript.cmd status dragonfly
.\libscript.cmd stop dragonfly
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/dragonfly/<version>`
  (default `~/.libscript/dragonfly/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `DRAGONFLY_INSTALL_METHOD` (or global
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

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DRAGONFLY_INSTALL_METHOD` | How to install dragonfly. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `DRAGONFLY_VERSION`        | Specific version of dragonfly to install.                                                                                                          | `latest`           | latest, lts      |
| `DRAGONFLY_DOWNLOAD_URL`   | Override URL for downloading dragonfly binary or archive artifacts.                                                                                | `none`             |                  |
| `DRAGONFLY_RELEASES_URL`   | Override URL for querying dragonfly available remote releases.                                                                                     | `none`             |                  |
| `DRAGONFLY_LISTEN_PORT`    | TCP port on which the dragonfly service listens.                                                                                                   | `6379`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
