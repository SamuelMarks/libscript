# Puma (`_lib/app-servers/puma/`)

## Overview

Fast, multithreaded, and highly concurrent HTTP 1.1 server for Ruby and Rack applications.

- **Tier**: `T1` (`_lib/app-servers/puma/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `puma`, `rack-server`, `app-server`

## Usage

```sh
# Install and manage the puma service daemon
./libscript.sh install puma latest
./libscript.sh start puma
./libscript.sh status puma
./libscript.sh logs puma
./libscript.sh stop puma
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install puma latest
.\libscript.cmd start puma
.\libscript.cmd status puma
.\libscript.cmd stop puma
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/puma/<version>`
  (default `~/.libscript/puma/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PUMA_INSTALL_METHOD` (or global
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
| `PUMA_INSTALL_METHOD` | How to install puma. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PUMA_VERSION`        | Specific version of puma to install.                                                                                                          | `latest`           | latest, lts      |
| `PUMA_DOWNLOAD_URL`   | Override URL for downloading puma binary or archive artifacts.                                                                                | `none`             |                  |
| `PUMA_RELEASES_URL`   | Override URL for querying puma available remote releases.                                                                                     | `none`             |                  |
| `PUMA_LISTEN_PORT`    | TCP port on which the puma service listens.                                                                                                   | `9292`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
