# Python App Server (`_lib/app-servers/python-server/`)

## Overview

Generic Python application server component (WSGI/ASGI).

- **Tier**: `T1` (`_lib/app-servers/python-server/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `app-server`, `python`, `wsgi`, `asgi`

## Usage

```sh
# Install and manage the python-server service daemon
./libscript.sh install python-server latest
./libscript.sh start python-server
./libscript.sh status python-server
./libscript.sh logs python-server
./libscript.sh stop python-server
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install python-server latest
.\libscript.cmd start python-server
.\libscript.cmd status python-server
.\libscript.cmd stop python-server
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/python-server/<version>` (default `~/.libscript/python-server/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `PYTHON_SERVER_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                                                                     | Default            | Aliases/Examples |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PYTHON_SERVER_DEST`           | Destination (working directory)                                                                                                                                 | `none`             |                  |
| `PYTHON_SERVER_VARS`           | Key/value in JSON format (as an escaped string)                                                                                                                 | `none`             |                  |
| `PYTHON_SERVER_VENV`           | Path to a Python virtualenv                                                                                                                                     | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`        | Global port to listen on                                                                                                                                        | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`     | Global address to listen on                                                                                                                                     | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`      | Global unix socket to listen on                                                                                                                                 | `none`             |                  |
| `PYTHON_SERVER_LISTEN_PORT`    | Port for PYTHON to listen on                                                                                                                                    | `none`             |                  |
| `PYTHON_SERVER_LISTEN_ADDRESS` | Address for PYTHON to listen on                                                                                                                                 | `none`             |                  |
| `PYTHON_SERVER_LISTEN_SOCKET`  | Unix socket for PYTHON to listen on                                                                                                                             | `none`             |                  |
| `PYTHON_SERVER_INSTALL_METHOD` | Installation strategy for python-server: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `PYTHON_SERVER_DOWNLOAD_URL`   | Override URL for downloading python-server binary or archive artifacts.                                                                                         | `none`             |                  |
| `PYTHON_SERVER_RELEASES_URL`   | Override URL for querying python-server available remote releases.                                                                                              | `none`             |                  |
| `PYTHON_SERVER_VERSION`        | Specific version of python-server to install (e.g., latest, lts, or exact version).                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
