# Skopeo Container Image Inspector & Copier (`_lib/containers/skopeo/`)

## Overview

Daemonless utility (skopeo) for inspecting, copying, signing, and synchronizing container images and
registries.

- **Tier**: `T1` (`_lib/containers/skopeo/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `macos`, `freebsd`, `openbsd`, `netbsd`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/skopeo/<version>)
./libscript.sh ls-remote skopeo
./libscript.sh install skopeo latest
./libscript.sh use skopeo latest
./libscript.sh which skopeo
./_lib/containers/skopeo/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote skopeo
.\libscript.cmd install skopeo latest
.\libscript.cmd use skopeo latest
.\libscript.cmd which skopeo
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/skopeo/<version>`
  (default `~/.libscript/skopeo/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SKOPEO_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SKOPEO_INSTALL_METHOD` | How to install skopeo. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SKOPEO_VERSION`        | Specific version of skopeo to install.                                                                                                          | `latest`           | latest, stable   |
| `SKOPEO_DOWNLOAD_URL`   | Override URL for downloading skopeo binary or archive artifacts.                                                                                | `none`             |                  |
| `SKOPEO_RELEASES_URL`   | Override URL for querying skopeo available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
