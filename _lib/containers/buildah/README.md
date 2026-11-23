# Buildah OCI Image Builder (`_lib/containers/buildah/`)

## Overview

Daemonless tool for building Open Container Initiative (OCI) and Docker container images.

- **Tier**: `T1` (`_lib/containers/buildah/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/buildah/<version>)
./libscript.sh ls-remote buildah
./libscript.sh install buildah latest
./libscript.sh use buildah latest
./libscript.sh which buildah
./_lib/containers/buildah/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote buildah
.\libscript.cmd install buildah latest
.\libscript.cmd use buildah latest
.\libscript.cmd which buildah
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/buildah/<version>`
  (default `~/.libscript/buildah/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `BUILDAH_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `BUILDAH_INSTALL_METHOD` | How to install buildah. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `BUILDAH_VERSION`        | Specific version of buildah to install.                                                                                                          | `latest`           | latest, stable   |
| `BUILDAH_DOWNLOAD_URL`   | Override URL for downloading buildah binary or archive artifacts.                                                                                | `none`             |                  |
| `BUILDAH_RELEASES_URL`   | Override URL for querying buildah available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
