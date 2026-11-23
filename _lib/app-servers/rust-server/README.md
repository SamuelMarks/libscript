# Rust App Server (`_lib/app-servers/rust-server/`)

## Overview

Generic Rust application server component.

- **Tier**: `T1` (`_lib/app-servers/rust-server/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `app-server`, `rust`

## Usage

```sh
# Install and manage the rust-server service daemon
./libscript.sh install rust-server latest
./libscript.sh start rust-server
./libscript.sh status rust-server
./libscript.sh logs rust-server
./libscript.sh stop rust-server
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install rust-server latest
.\libscript.cmd start rust-server
.\libscript.cmd status rust-server
.\libscript.cmd stop rust-server
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/rust-server/<version>` (default `~/.libscript/rust-server/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `RUST_SERVER_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                                   | Default            | Aliases/Examples |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RUST_SERVER_DEST`           | Destination (working directory)                                                                                                                               | `none`             |                  |
| `RUST_SERVER_VARS`           | Key/value in JSON format (as an escaped string)                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`      | Global port to listen on                                                                                                                                      | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`   | Global address to listen on                                                                                                                                   | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`    | Global unix socket to listen on                                                                                                                               | `none`             |                  |
| `RUST_SERVER_LISTEN_PORT`    | Port for RUST to listen on                                                                                                                                    | `none`             |                  |
| `RUST_SERVER_LISTEN_ADDRESS` | Address for RUST to listen on                                                                                                                                 | `none`             |                  |
| `RUST_SERVER_LISTEN_SOCKET`  | Unix socket for RUST to listen on                                                                                                                             | `none`             |                  |
| `RUST_SERVER_INSTALL_METHOD` | Installation strategy for rust-server: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `RUST_SERVER_DOWNLOAD_URL`   | Override URL for downloading rust-server binary or archive artifacts.                                                                                         | `none`             |                  |
| `RUST_SERVER_RELEASES_URL`   | Override URL for querying rust-server available remote releases.                                                                                              | `none`             |                  |
| `RUST_SERVER_VERSION`        | Specific version of rust-server to install (e.g., latest, lts, or exact version).                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
