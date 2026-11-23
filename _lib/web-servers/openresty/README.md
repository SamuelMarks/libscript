# OpenResty (`_lib/web-servers/openresty/`)

## Overview

Dynamic web platform based on Nginx and LuaJIT for high-concurrency API gateways and web apps.

- **Tier**: `T1` (`_lib/web-servers/openresty/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `openresty`, `web-server`, `reverse-proxy`

## Usage

```sh
# Install and manage the openresty service daemon
./libscript.sh install openresty latest
./libscript.sh start openresty
./libscript.sh status openresty
./libscript.sh logs openresty
./libscript.sh stop openresty
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install openresty latest
.\libscript.cmd start openresty
.\libscript.cmd status openresty
.\libscript.cmd stop openresty
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/openresty/<version>`
  (default `~/.libscript/openresty/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OPENRESTY_INSTALL_METHOD` (or global
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

| Variable                   | Description                                                                                                                                        | Default  | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `OPENRESTY_INSTALL_METHOD` | How to install openresty. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `OPENRESTY_VERSION`        | Specific version of openresty to install.                                                                                                          | `latest` | latest, lts      |
| `OPENRESTY_DOWNLOAD_URL`   | Override URL for downloading openresty binary or archive artifacts.                                                                                | `none`   |                  |
| `OPENRESTY_RELEASES_URL`   | Override URL for querying openresty available remote releases.                                                                                     | `none`   |                  |
| `OPENRESTY_LISTEN_PORT`    | TCP port on which the openresty service listens.                                                                                                   | `80`     |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
