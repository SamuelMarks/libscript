# OpenZFS (`_lib/storage-layers/zfs/`)

## Overview

OpenZFS copy-on-write enterprise filesystem and logical volume administration utilities (zfs and
zpool).

- **Tier**: `T1` (`_lib/storage-layers/zfs/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `zfs`, `zpool`, `openzfs`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/zfs/<version>)
./libscript.sh ls-remote zfs
./libscript.sh install zfs latest
./libscript.sh use zfs latest
./libscript.sh which zfs
./_lib/storage-layers/zfs/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote zfs
.\libscript.cmd install zfs latest
.\libscript.cmd use zfs latest
.\libscript.cmd which zfs
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/zfs/<version>`
  (default `~/.libscript/zfs/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ZFS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `ZFS_INSTALL_METHOD` | How to install zfs. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `ZFS_VERSION`        | Specific version of zfs to install.                                                                                                          | `latest` | latest, lts      |
| `ZFS_DOWNLOAD_URL`   | Override URL for downloading zfs binary or archive artifacts.                                                                                | `none`   |                  |
| `ZFS_RELEASES_URL`   | Override URL for querying zfs available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
