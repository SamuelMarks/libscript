# Keepalived VRRP & LVS High-Availability Daemon (`_lib/networking/keepalived/`)

## Overview

Keepalived VRRPv2/v3 virtual router redundancy and Linux Virtual Server (IPVS) load-balancing
healthcheck daemon.

- **Tier**: `T1` (`_lib/networking/keepalived/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/keepalived/<version>)
./libscript.sh ls-remote keepalived
./libscript.sh install keepalived latest
./libscript.sh use keepalived latest
./libscript.sh which keepalived
./_lib/networking/keepalived/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote keepalived
.\libscript.cmd install keepalived latest
.\libscript.cmd use keepalived latest
.\libscript.cmd which keepalived
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/keepalived/<version>`
  (default `~/.libscript/keepalived/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `KEEPALIVED_INSTALL_METHOD` (or global
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

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KEEPALIVED_INSTALL_METHOD` | How to install keepalived. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `KEEPALIVED_VERSION`        | Specific version of keepalived to install.                                                                                                          | `latest`           | latest, stable   |
| `KEEPALIVED_DOWNLOAD_URL`   | Override URL for downloading keepalived binary or archive artifacts.                                                                                | `none`             |                  |
| `KEEPALIVED_RELEASES_URL`   | Override URL for querying keepalived available remote releases.                                                                                     | `none`             |                  |
| `KEEPALIVED_LISTEN_PORT`    | TCP port on which the keepalived service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
