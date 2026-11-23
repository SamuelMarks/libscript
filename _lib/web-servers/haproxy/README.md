# HAProxy (`_lib/web-servers/haproxy/`)

## Overview

Reliable, high-performance TCP/HTTP load balancer and proxy server for high-availability systems.

- **Tier**: `T1` (`_lib/web-servers/haproxy/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `haproxy`, `load-balancer`, `reverse-proxy`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the haproxy service daemon
./libscript.sh install haproxy latest
./libscript.sh start haproxy
./libscript.sh status haproxy
./libscript.sh logs haproxy
./libscript.sh stop haproxy
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install haproxy latest
.\libscript.cmd start haproxy
.\libscript.cmd status haproxy
.\libscript.cmd stop haproxy
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/haproxy/<version>`
  (default `~/.libscript/haproxy/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `HAPROXY_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `HAPROXY_INSTALL_METHOD` | How to install haproxy. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `HAPROXY_VERSION`        | Specific version of haproxy to install.                                                                                                          | `latest` | latest, lts      |
| `HAPROXY_DOWNLOAD_URL`   | Override URL for downloading haproxy binary or archive artifacts.                                                                                | `none`   |                  |
| `HAPROXY_RELEASES_URL`   | Override URL for querying haproxy available remote releases.                                                                                     | `none`   |                  |
| `HAPROXY_LISTEN_PORT`    | TCP port on which the haproxy service listens.                                                                                                   | `80`     |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
