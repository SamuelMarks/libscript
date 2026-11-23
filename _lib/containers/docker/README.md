# Docker (`_lib/containers/docker/`)

## Overview

A platform for developing, shipping, and running containerized applications.

- **Tier**: `T1` (`_lib/containers/docker/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `docker`, `orchestration`, `containers`, `runtime`, `server`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`
- **Target OS Exclusions (`manifest.json`)**: `freebsd`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/docker/<version>)
./libscript.sh ls-remote docker
./libscript.sh install docker latest
./libscript.sh use docker latest
./libscript.sh which docker
./_lib/containers/docker/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote docker
.\libscript.cmd install docker latest
.\libscript.cmd use docker latest
.\libscript.cmd which docker
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/docker/<version>`
  (default `~/.libscript/docker/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `DOCKER_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                              | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DOCKER_VERSION`           | Specific version of docker to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `DOCKER_INSTALL_METHOD`    | Installation strategy for docker: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                              | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                          | `none`             |                  |
| `DOCKER_LISTEN_PORT`       | Port for DOCKER to listen on                                                                                                                             | `none`             |                  |
| `DOCKER_LISTEN_ADDRESS`    | Address for DOCKER to listen on                                                                                                                          | `none`             |                  |
| `DOCKER_LISTEN_SOCKET`     | Unix socket for DOCKER to listen on                                                                                                                      | `none`             |                  |
| `DOCKER_DOWNLOAD_URL`      | Override URL for downloading docker binary or archive artifacts.                                                                                         | `none`             |                  |
| `DOCKER_RELEASES_URL`      | Override URL for querying docker available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
