# Traefik (`_lib/web-servers/traefik/`)

## Overview

Modern HTTP reverse proxy and cloud-native edge router with automatic service discovery and TLS.

- **Tier**: `T1` (`_lib/web-servers/traefik/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `traefik`, `reverse-proxy`, `edge-router`, `web-server`

## Usage

```sh
# Install and manage the traefik service daemon
./libscript.sh install traefik latest
./libscript.sh start traefik
./libscript.sh status traefik
./libscript.sh logs traefik
./libscript.sh stop traefik
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install traefik latest
.\libscript.cmd start traefik
.\libscript.cmd status traefik
.\libscript.cmd stop traefik
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/traefik/<version>`
  (default `~/.libscript/traefik/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `TRAEFIK_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `TRAEFIK_INSTALL_METHOD` | How to install traefik. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TRAEFIK_VERSION`        | Specific version of traefik to install.                                                                                                          | `latest`           | latest, lts      |
| `TRAEFIK_DOWNLOAD_URL`   | Override URL for downloading traefik binary or archive artifacts.                                                                                | `none`             |                  |
| `TRAEFIK_RELEASES_URL`   | Override URL for querying traefik available remote releases.                                                                                     | `none`             |                  |
| `TRAEFIK_LISTEN_PORT`    | TCP port on which the traefik service listens.                                                                                                   | `80`               |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
