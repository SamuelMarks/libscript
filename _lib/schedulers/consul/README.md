# HashiCorp Consul (`_lib/schedulers/consul/`)

## Overview

HashiCorp Consul service mesh, multi-datacenter service discovery, health checking, and distributed
key-value store.

- **Tier**: `T1` (`_lib/schedulers/consul/`)
- **Capabilities**: `userland-package`, `service-daemon`

## Usage

```sh
# Install and manage the consul service daemon
./libscript.sh install consul latest
./libscript.sh start consul
./libscript.sh status consul
./libscript.sh logs consul
./libscript.sh stop consul
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install consul latest
.\libscript.cmd start consul
.\libscript.cmd status consul
.\libscript.cmd stop consul
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/consul/<version>`
  (default `~/.libscript/consul/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CONSUL_INSTALL_METHOD` (or global
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

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CONSUL_INSTALL_METHOD` | How to install consul. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CONSUL_VERSION`        | Specific version of consul to install.                                                                                                          | `latest`           | latest, stable   |
| `CONSUL_DOWNLOAD_URL`   | Override URL for downloading consul binary or archive artifacts.                                                                                | `none`             |                  |
| `CONSUL_RELEASES_URL`   | Override URL for querying consul available remote releases.                                                                                     | `none`             |                  |
| `CONSUL_LISTEN_PORT`    | TCP port on which the consul service listens.                                                                                                   | `8500`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
