# Podman Daemonless Container Engine (`_lib/containers/podman/`)

## Overview

Daemonless, rootless OCI container and pod management engine (podman) compatible with Docker CLI
workflows.

- **Tier**: `T1` (`_lib/containers/podman/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/podman/<version>)
./libscript.sh ls-remote podman
./libscript.sh install podman latest
./libscript.sh use podman latest
./libscript.sh which podman
./_lib/containers/podman/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote podman
.\libscript.cmd install podman latest
.\libscript.cmd use podman latest
.\libscript.cmd which podman
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/podman/<version>`
  (default `~/.libscript/podman/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PODMAN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PODMAN_INSTALL_METHOD` | How to install podman. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PODMAN_VERSION`        | Specific version of podman to install.                                                                                                          | `latest`           | latest, stable   |
| `PODMAN_DOWNLOAD_URL`   | Override URL for downloading podman binary or archive artifacts.                                                                                | `none`             |                  |
| `PODMAN_RELEASES_URL`   | Override URL for querying podman available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
