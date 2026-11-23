# Symas LMDB (`_lib/databases/lmdb/`)

## Overview

Symas Lightning Memory-Mapped Database ultra-fast, ultra-compact transactional embedded key-value
store tools.

- **Tier**: `T1` (`_lib/databases/lmdb/`)
- **Capabilities**: `userland-package`, `sysroot-library`
- **Provides Virtual Capabilities**: `lmdb`, `kv-store`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/lmdb/<version>)
./libscript.sh ls-remote lmdb
./libscript.sh install lmdb latest
./libscript.sh use lmdb latest
./libscript.sh which lmdb
./_lib/databases/lmdb/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote lmdb
.\libscript.cmd install lmdb latest
.\libscript.cmd use lmdb latest
.\libscript.cmd which lmdb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/lmdb/<version>`
  (default `~/.libscript/lmdb/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LMDB_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `LMDB_INSTALL_METHOD` | How to install lmdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `LMDB_VERSION`        | Specific version of lmdb to install.                                                                                                          | `latest` | latest, lts      |
| `LMDB_DOWNLOAD_URL`   | Override URL for downloading lmdb binary or archive artifacts.                                                                                | `none`   |                  |
| `LMDB_RELEASES_URL`   | Override URL for querying lmdb available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
