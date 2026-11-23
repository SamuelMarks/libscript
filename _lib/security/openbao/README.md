# OpenBao (`_lib/security/openbao/`)

## Overview

An open-source tool for managing secrets and protecting sensitive data.

- **Tier**: `T1` (`_lib/security/openbao/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `openbao`, `security`, `secrets`, `server`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the openbao service daemon
./libscript.sh install openbao latest
./libscript.sh start openbao
./libscript.sh status openbao
./libscript.sh logs openbao
./libscript.sh stop openbao
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install openbao latest
.\libscript.cmd start openbao
.\libscript.cmd status openbao
.\libscript.cmd stop openbao
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/openbao/<version>`
  (default `~/.libscript/openbao/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OPENBAO_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                                                               | Default             | Aliases/Examples |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ---------------- |
| `OPENBAO_VERSION`                 | Specific version of openbao to install. Can be a numeric version or an alias.                                                                             | `latest`            | latest, stable   |
| `OPENBAO_INSTALL_METHOD`          | Installation strategy for openbao: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native`  |                  |
| `LIBSCRIPT_LISTEN_PORT`           | Global port to listen on                                                                                                                                  | `none`              |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`        | Global address to listen on                                                                                                                               | `none`              |                  |
| `LIBSCRIPT_LISTEN_SOCKET`         | Global unix socket to listen on                                                                                                                           | `none`              |                  |
| `OPENBAO_LISTEN_PORT`             | Port for OPENBAO to listen on                                                                                                                             | `none`              |                  |
| `OPENBAO_LISTEN_ADDRESS`          | Address for OPENBAO to listen on                                                                                                                          | `none`              |                  |
| `OPENBAO_LISTEN_SOCKET`           | Unix socket for OPENBAO to listen on                                                                                                                      | `none`              |                  |
| `OPENBAO_SERVICE_RUN_AS_USER`     | Windows local user account to run the service under (leave empty for Network Service).                                                                    | `none`              |                  |
| `OPENBAO_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable).                                                                                              | `none`              |                  |
| `OPENBAO_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations).                                                                                  | `libscript_openbao` |                  |
| `OPENBAO_DOWNLOAD_URL`            | Override URL for downloading openbao binary or archive artifacts.                                                                                         | `none`              |                  |
| `OPENBAO_RELEASES_URL`            | Override URL for querying openbao available remote releases.                                                                                              | `none`              |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
