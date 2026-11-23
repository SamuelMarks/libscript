# Uncomplicated Firewall (UFW) (`_lib/networking/ufw/`)

## Overview

Uncomplicated Firewall (ufw) command-line host firewall configuration frontend for
netfilter/iptables and nftables.

- **Tier**: `T1` (`_lib/networking/ufw/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ufw/<version>)
./libscript.sh ls-remote ufw
./libscript.sh install ufw latest
./libscript.sh use ufw latest
./libscript.sh which ufw
./_lib/networking/ufw/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ufw
.\libscript.cmd install ufw latest
.\libscript.cmd use ufw latest
.\libscript.cmd which ufw
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ufw/<version>`
  (default `~/.libscript/ufw/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `UFW_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `UFW_INSTALL_METHOD` | How to install ufw. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `UFW_VERSION`        | Specific version of ufw to install.                                                                                                          | `latest`           | latest, stable   |
| `UFW_DOWNLOAD_URL`   | Override URL for downloading ufw binary or archive artifacts.                                                                                | `none`             |                  |
| `UFW_RELEASES_URL`   | Override URL for querying ufw available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
