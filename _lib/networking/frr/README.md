# FRRouting (FRR) Routing Suite (`_lib/networking/frr/`)

## Overview

FRRouting IP routing protocol suite implementing BGP, OSPF, RIP, IS-IS, PIM, LDP, BFD, Babel, and
EVPN (vtysh, zebra, bgpd, ospfd).

- **Tier**: `T1` (`_lib/networking/frr/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `frr`, `frrouting`, `vtysh`, `bgpd`, `ospfd`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the frr service daemon
./libscript.sh install frr latest
./libscript.sh start frr
./libscript.sh status frr
./libscript.sh logs frr
./libscript.sh stop frr
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install frr latest
.\libscript.cmd start frr
.\libscript.cmd status frr
.\libscript.cmd stop frr
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/frr/<version>`
  (default `~/.libscript/frr/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `FRR_INSTALL_METHOD` (or global
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

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FRR_INSTALL_METHOD` | How to install frr. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FRR_VERSION`        | Specific version of frr to install.                                                                                                          | `latest`           | latest, stable   |
| `FRR_DOWNLOAD_URL`   | Override URL for downloading frr binary or archive artifacts.                                                                                | `none`             |                  |
| `FRR_RELEASES_URL`   | Override URL for querying frr available remote releases.                                                                                     | `none`             |                  |
| `FRR_LISTEN_PORT`    | TCP port on which the frr service listens.                                                                                                   | `179`              |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
