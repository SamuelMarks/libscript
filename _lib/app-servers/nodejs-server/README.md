# Node.js App Server (`_lib/app-servers/nodejs-server/`)

## Overview

Generic Node.js application server component.

- **Tier**: `T1` (`_lib/app-servers/nodejs-server/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `app-server`, `nodejs`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the nodejs-server service daemon
./libscript.sh install nodejs-server latest
./libscript.sh start nodejs-server
./libscript.sh status nodejs-server
./libscript.sh logs nodejs-server
./libscript.sh stop nodejs-server
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install nodejs-server latest
.\libscript.cmd start nodejs-server
.\libscript.cmd status nodejs-server
.\libscript.cmd stop nodejs-server
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/nodejs-server/<version>` (default `~/.libscript/nodejs-server/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `NODEJS_SERVER_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                                                                     | Default            | Aliases/Examples |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NODEJS_SERVER_DEST`           | Destination (working directory)                                                                                                                                 | `none`             |                  |
| `NODEJS_SERVER_VARS`           | Key/value in JSON format (as an escaped string)                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`        | Global port to listen on                                                                                                                                        | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`     | Global address to listen on                                                                                                                                     | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`      | Global unix socket to listen on                                                                                                                                 | `none`             |                  |
| `NODEJS_SERVER_LISTEN_PORT`    | Port for NODEJS to listen on                                                                                                                                    | `none`             |                  |
| `NODEJS_SERVER_LISTEN_ADDRESS` | Address for NODEJS to listen on                                                                                                                                 | `none`             |                  |
| `NODEJS_SERVER_LISTEN_SOCKET`  | Unix socket for NODEJS to listen on                                                                                                                             | `none`             |                  |
| `NODEJS_SERVER_INSTALL_METHOD` | Installation strategy for nodejs-server: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `NODEJS_SERVER_DOWNLOAD_URL`   | Override URL for downloading nodejs-server binary or archive artifacts.                                                                                         | `none`             |                  |
| `NODEJS_SERVER_RELEASES_URL`   | Override URL for querying nodejs-server available remote releases.                                                                                              | `none`             |                  |
| `NODEJS_SERVER_VERSION`        | Specific version of nodejs-server to install (e.g., latest, lts, or exact version).                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
