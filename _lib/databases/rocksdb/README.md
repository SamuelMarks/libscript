# RocksDB (`_lib/databases/rocksdb/`)

## Overview

Embeddable persistent LSM-tree key-value store library and ldb administration CLI tools optimized
for fast flash storage.

- **Tier**: `T1` (`_lib/databases/rocksdb/`)
- **Capabilities**: `userland-package`, `sysroot-library`
- **Provides Virtual Capabilities**: `rocksdb`, `ldb`, `kv-store`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/rocksdb/<version>)
./libscript.sh ls-remote rocksdb
./libscript.sh install rocksdb latest
./libscript.sh use rocksdb latest
./libscript.sh which rocksdb
./_lib/databases/rocksdb/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote rocksdb
.\libscript.cmd install rocksdb latest
.\libscript.cmd use rocksdb latest
.\libscript.cmd which rocksdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/rocksdb/<version>`
  (default `~/.libscript/rocksdb/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `ROCKSDB_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `ROCKSDB_INSTALL_METHOD` | How to install rocksdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `ROCKSDB_VERSION`        | Specific version of rocksdb to install.                                                                                                          | `latest` | latest, lts      |
| `ROCKSDB_DOWNLOAD_URL`   | Override URL for downloading rocksdb binary or archive artifacts.                                                                                | `none`   |                  |
| `ROCKSDB_RELEASES_URL`   | Override URL for querying rocksdb available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
