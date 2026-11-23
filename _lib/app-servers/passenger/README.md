# Phusion Passenger (`_lib/app-servers/passenger/`)

## Overview

Polyglot web and application server supporting Ruby, Node.js, Python, and Meteor workloads.

- **Tier**: `T1` (`_lib/app-servers/passenger/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `passenger`, `rack-server`, `app-server`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the passenger service daemon
./libscript.sh install passenger latest
./libscript.sh start passenger
./libscript.sh status passenger
./libscript.sh logs passenger
./libscript.sh stop passenger
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install passenger latest
.\libscript.cmd start passenger
.\libscript.cmd status passenger
.\libscript.cmd stop passenger
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/passenger/<version>`
  (default `~/.libscript/passenger/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `PASSENGER_INSTALL_METHOD` (or global
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
| `PASSENGER_INSTALL_METHOD` | How to install passenger. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PASSENGER_VERSION`        | Specific version of passenger to install.                                                                                                          | `latest`           | latest, lts      |
| `PASSENGER_DOWNLOAD_URL`   | Override URL for downloading passenger binary or archive artifacts.                                                                                | `none`             |                  |
| `PASSENGER_RELEASES_URL`   | Override URL for querying passenger available remote releases.                                                                                     | `none`             |                  |
| `PASSENGER_LISTEN_PORT`    | TCP port on which the passenger service listens.                                                                                                   | `3000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
