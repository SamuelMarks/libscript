# Dnsmasq DNS/DHCP/TFTP Server (`_lib/networking/dnsmasq/`)

## Overview

Lightweight DNS forwarder, DHCPv4/v6 server, router advertisement, and PXE/TFTP network boot server.

- **Tier**: `T1` (`_lib/networking/dnsmasq/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `macos`, `freebsd`, `openbsd`, `netbsd`,
  `sunos`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the dnsmasq service daemon
./libscript.sh install dnsmasq latest
./libscript.sh start dnsmasq
./libscript.sh status dnsmasq
./libscript.sh logs dnsmasq
./libscript.sh stop dnsmasq
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install dnsmasq latest
.\libscript.cmd start dnsmasq
.\libscript.cmd status dnsmasq
.\libscript.cmd stop dnsmasq
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/dnsmasq/<version>`
  (default `~/.libscript/dnsmasq/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `DNSMASQ_INSTALL_METHOD` (or global
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
| `DNSMASQ_INSTALL_METHOD` | How to install dnsmasq. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `DNSMASQ_VERSION`        | Specific version of dnsmasq to install.                                                                                                          | `latest`           | latest, stable   |
| `DNSMASQ_DOWNLOAD_URL`   | Override URL for downloading dnsmasq binary or archive artifacts.                                                                                | `none`             |                  |
| `DNSMASQ_RELEASES_URL`   | Override URL for querying dnsmasq available remote releases.                                                                                     | `none`             |                  |
| `DNSMASQ_LISTEN_PORT`    | TCP port on which the dnsmasq service listens.                                                                                                   | `53`               |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
