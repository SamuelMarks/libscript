# Cloud Storage FUSE (gcsfuse) (`_lib/storage-layers/gcsfuse/`)

## Overview

Cloud Storage FUSE allows you to mount Cloud Storage buckets as file systems on Linux or macOS
systems.

- **Tier**: `T1` (`_lib/storage-layers/gcsfuse/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`
- **Target OS Exclusions (`manifest.json`)**: `freebsd`, `windows`, `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/gcsfuse/<version>)
./libscript.sh ls-remote gcsfuse
./libscript.sh install gcsfuse latest
./libscript.sh use gcsfuse latest
./libscript.sh which gcsfuse
./_lib/storage-layers/gcsfuse/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote gcsfuse
.\libscript.cmd install gcsfuse latest
.\libscript.cmd use gcsfuse latest
.\libscript.cmd which gcsfuse
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/gcsfuse/<version>`
  (default `~/.libscript/gcsfuse/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GCSFUSE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                       | Default            | Aliases/Examples |
| ------------------------ | ----------------------------------------------------------------- | ------------------ | ---------------- |
| `GCSFUSE_VERSION`        | Specific version of gcsfuse to install.                           | `latest`           | latest, stable   |
| `GCSFUSE_INSTALL_METHOD` | How to install gcsfuse.                                           | `libscript_native` |                  |
| `GCSFUSE_DOWNLOAD_URL`   | Override URL for downloading gcsfuse binary or archive artifacts. | `none`             |                  |
| `GCSFUSE_RELEASES_URL`   | Override URL for querying gcsfuse available remote releases.      | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
