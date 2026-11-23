# WireGuard Tools (`_lib/security/wireguard/`)

## Overview

Fast, modern, cryptographically opinionated VPN tunnel configuration utilities (wg and wg-quick).

- **Tier**: `T1` (`_lib/security/wireguard/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `wireguard`, `wg`, `vpn`

## Usage

```sh
# Install and manage the wireguard service daemon
./libscript.sh install wireguard latest
./libscript.sh start wireguard
./libscript.sh status wireguard
./libscript.sh logs wireguard
./libscript.sh stop wireguard
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install wireguard latest
.\libscript.cmd start wireguard
.\libscript.cmd status wireguard
.\libscript.cmd stop wireguard
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/wireguard/<version>`
  (default `~/.libscript/wireguard/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `WIREGUARD_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default  | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `WIREGUARD_INSTALL_METHOD` | How to install wireguard. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `WIREGUARD_VERSION`        | Specific version of wireguard to install.                                                                                                          | `latest` | latest, lts      |
| `WIREGUARD_DOWNLOAD_URL`   | Override URL for downloading wireguard binary or archive artifacts.                                                                                | `none`   |                  |
| `WIREGUARD_RELEASES_URL`   | Override URL for querying wireguard available remote releases.                                                                                     | `none`   |                  |
| `WIREGUARD_LISTEN_PORT`    | TCP port on which the wireguard service listens.                                                                                                   | `51820`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
