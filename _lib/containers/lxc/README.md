# Linux Containers (LXC) Userspace Tools (`_lib/containers/lxc/`)

## Overview

Low-level Linux Containers userspace tools and library (lxc-create, lxc-start, lxc-ls, lxc-attach)
over kernel namespaces and cgroups.

- **Tier**: `T1` (`_lib/containers/lxc/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `lxc`, `lxc-ls`, `lxc-create`
- **Target OS Whitelist (`manifest.json`)**: `linux`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/lxc/<version>)
./libscript.sh ls-remote lxc
./libscript.sh install lxc latest
./libscript.sh use lxc latest
./libscript.sh which lxc
./_lib/containers/lxc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote lxc
.\libscript.cmd install lxc latest
.\libscript.cmd use lxc latest
.\libscript.cmd which lxc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/lxc/<version>`
  (default `~/.libscript/lxc/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LXC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples    |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------- |
| `LXC_INSTALL_METHOD` | How to install lxc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                     |
| `LXC_VERSION`        | Specific version of lxc to install.                                                                                                          | `latest`           | latest, stable, lts |
| `LXC_DOWNLOAD_URL`   | Override URL for downloading lxc binary or archive artifacts.                                                                                | `none`             |                     |
| `LXC_RELEASES_URL`   | Override URL for querying lxc available remote releases.                                                                                     | `none`             |                     |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
