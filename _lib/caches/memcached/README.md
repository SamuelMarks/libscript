# Memcached (`_lib/caches/memcached/`)

## Overview

High-performance, distributed memory object caching system.

- **Tier**: `T1` (`_lib/caches/memcached/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `cache`, `memcached`, `key-value`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Install and manage the memcached service daemon
./libscript.sh install memcached latest
./libscript.sh start memcached
./libscript.sh status memcached
./libscript.sh logs memcached
./libscript.sh stop memcached
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install memcached latest
.\libscript.cmd start memcached
.\libscript.cmd status memcached
.\libscript.cmd stop memcached
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/memcached/<version>`
  (default `~/.libscript/memcached/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `MEMCACHED_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                 | Default            | Aliases/Examples |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MEMCACHED_VERSION`              | Specific version of memcached to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `MEMCACHED_INSTALL_METHOD`       | Installation strategy for memcached: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`          | Global port to listen on                                                                                                                                    | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`       | Global address to listen on                                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`        | Global unix socket to listen on                                                                                                                             | `none`             |                  |
| `MEMCACHED_LISTEN_PORT`          | Port for MEMCACHED to listen on                                                                                                                             | `11211`            |                  |
| `MEMCACHED_PORT_CONFLICT_POLICY` | Policy if configured port is occupied: abort, auto-increment, or reuse                                                                                      | `abort`            |                  |
| `MEMCACHED_LISTEN_ADDRESS`       | Address for MEMCACHED to listen on                                                                                                                          | `none`             |                  |
| `MEMCACHED_LISTEN_SOCKET`        | Unix socket for MEMCACHED to listen on                                                                                                                      | `none`             |                  |
| `MEMCACHED_DOWNLOAD_URL`         | Custom download URL for memcached binary or source archive                                                                                                  | `none`             |                  |
| `MEMCACHED_LISTEN`               | Listen endpoint (address:port or socket) for memcached.                                                                                                     | `none`             |                  |
| `MEMCACHED_RELEASES_URL`         | Override URL for querying memcached available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
