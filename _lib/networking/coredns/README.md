# CoreDNS (`_lib/networking/coredns/`)

## Overview

CoreDNS cloud-native, plugin-driven DNS server and service discovery engine.

- **Tier**: `T1` (`_lib/networking/coredns/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `coredns`, `dns-server`

## Usage

```sh
# Install and manage the coredns service daemon
./libscript.sh install coredns latest
./libscript.sh start coredns
./libscript.sh status coredns
./libscript.sh logs coredns
./libscript.sh stop coredns
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install coredns latest
.\libscript.cmd start coredns
.\libscript.cmd status coredns
.\libscript.cmd stop coredns
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/coredns/<version>`
  (default `~/.libscript/coredns/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `COREDNS_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `COREDNS_INSTALL_METHOD` | How to install coredns. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `COREDNS_VERSION`        | Specific version of coredns to install.                                                                                                          | `latest`           | latest, stable   |
| `COREDNS_DOWNLOAD_URL`   | Override URL for downloading coredns binary or archive artifacts.                                                                                | `none`             |                  |
| `COREDNS_RELEASES_URL`   | Override URL for querying coredns available remote releases.                                                                                     | `none`             |                  |
| `COREDNS_LISTEN_PORT`    | TCP port on which the coredns service listens.                                                                                                   | `53`               |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
