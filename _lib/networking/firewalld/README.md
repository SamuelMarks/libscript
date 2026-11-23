# Firewalld Dynamic Firewall Daemon (`_lib/networking/firewalld/`)

## Overview

Dynamically managed Linux firewall daemon (firewalld and firewall-cmd) supporting network/firewall
zones over nftables and iptables.

- **Tier**: `T1` (`_lib/networking/firewalld/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `firewalld`, `firewall-cmd`
- **Target OS Whitelist (`manifest.json`)**: `linux`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/firewalld/<version>)
./libscript.sh ls-remote firewalld
./libscript.sh install firewalld latest
./libscript.sh use firewalld latest
./libscript.sh which firewalld
./_lib/networking/firewalld/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote firewalld
.\libscript.cmd install firewalld latest
.\libscript.cmd use firewalld latest
.\libscript.cmd which firewalld
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/firewalld/<version>`
  (default `~/.libscript/firewalld/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `FIREWALLD_INSTALL_METHOD` (or global
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

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FIREWALLD_INSTALL_METHOD` | How to install firewalld. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FIREWALLD_VERSION`        | Specific version of firewalld to install.                                                                                                          | `latest`           | latest, stable   |
| `FIREWALLD_DOWNLOAD_URL`   | Override URL for downloading firewalld binary or archive artifacts.                                                                                | `none`             |                  |
| `FIREWALLD_RELEASES_URL`   | Override URL for querying firewalld available remote releases.                                                                                     | `none`             |                  |
| `FIREWALLD_LISTEN_PORT`    | TCP port on which the firewalld service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
