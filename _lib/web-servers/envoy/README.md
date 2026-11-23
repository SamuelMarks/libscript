# Envoy (`_lib/web-servers/envoy/`)

## Overview

Cloud-native high-performance C++ distributed L4/L7 edge and service proxy.

- **Tier**: `T1` (`_lib/web-servers/envoy/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `envoy`, `reverse-proxy`, `edge-router`, `load-balancer`,
  `web-server`

## Usage

```sh
# Install and manage the envoy service daemon
./libscript.sh install envoy latest
./libscript.sh start envoy
./libscript.sh status envoy
./libscript.sh logs envoy
./libscript.sh stop envoy
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install envoy latest
.\libscript.cmd start envoy
.\libscript.cmd status envoy
.\libscript.cmd stop envoy
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/envoy/<version>`
  (default `~/.libscript/envoy/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ENVOY_INSTALL_METHOD` (or global
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
| `ENVOY_INSTALL_METHOD` | How to install envoy. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `ENVOY_VERSION`        | Specific version of envoy to install.                                                                                                          | `latest`           | latest, lts      |
| `ENVOY_DOWNLOAD_URL`   | Override URL for downloading envoy binary or archive artifacts.                                                                                | `none`             |                  |
| `ENVOY_RELEASES_URL`   | Override URL for querying envoy available remote releases.                                                                                     | `none`             |                  |
| `ENVOY_LISTEN_PORT`    | TCP port on which the envoy service listens.                                                                                                   | `10000`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
