# PM2 (`_lib/app-servers/pm2/`)

## Overview

Production process manager and cluster load balancer for Node.js and polyglot applications.

- **Tier**: `T1` (`_lib/app-servers/pm2/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `pm2`, `process-manager`, `app-server`

## Usage

```sh
# Install and manage the pm2 service daemon
./libscript.sh install pm2 latest
./libscript.sh start pm2
./libscript.sh status pm2
./libscript.sh logs pm2
./libscript.sh stop pm2
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install pm2 latest
.\libscript.cmd start pm2
.\libscript.cmd status pm2
.\libscript.cmd stop pm2
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/pm2/<version>`
  (default `~/.libscript/pm2/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PM2_INSTALL_METHOD` (or global
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

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PM2_INSTALL_METHOD` | How to install pm2. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PM2_VERSION`        | Specific version of pm2 to install.                                                                                                          | `latest`           | latest, lts      |
| `PM2_DOWNLOAD_URL`   | Override URL for downloading pm2 binary or archive artifacts.                                                                                | `none`             |                  |
| `PM2_RELEASES_URL`   | Override URL for querying pm2 available remote releases.                                                                                     | `none`             |                  |
| `PM2_LISTEN_PORT`    | TCP port on which the pm2 service listens.                                                                                                   | `9615`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
