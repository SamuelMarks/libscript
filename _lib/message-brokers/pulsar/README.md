# Apache Pulsar (`_lib/message-brokers/pulsar/`)

## Overview

Cloud-native distributed messaging and streaming platform with tiered storage and multi-tenancy.

- **Tier**: `T1` (`_lib/message-brokers/pulsar/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `pulsar`, `message-broker`, `streaming`

## Usage

```sh
# Install and manage the pulsar service daemon
./libscript.sh install pulsar latest
./libscript.sh start pulsar
./libscript.sh status pulsar
./libscript.sh logs pulsar
./libscript.sh stop pulsar
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install pulsar latest
.\libscript.cmd start pulsar
.\libscript.cmd status pulsar
.\libscript.cmd stop pulsar
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/pulsar/<version>`
  (default `~/.libscript/pulsar/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PULSAR_INSTALL_METHOD` (or global
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

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PULSAR_INSTALL_METHOD` | How to install pulsar. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PULSAR_VERSION`        | Specific version of pulsar to install.                                                                                                          | `latest`           | latest, lts      |
| `PULSAR_DOWNLOAD_URL`   | Override URL for downloading pulsar binary or archive artifacts.                                                                                | `none`             |                  |
| `PULSAR_RELEASES_URL`   | Override URL for querying pulsar available remote releases.                                                                                     | `none`             |                  |
| `PULSAR_LISTEN_PORT`    | TCP port on which the pulsar service listens.                                                                                                   | `6650`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
