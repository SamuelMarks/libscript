# TimescaleDB (`_lib/databases/timescaledb/`)

## Overview

Open-source time-series SQL database extension and tuning toolkit engineered on PostgreSQL.

- **Tier**: `T1` (`_lib/databases/timescaledb/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `timescaledb`, `tsdb`, `postgres-extension`

## Usage

```sh
# Install and manage the timescaledb service daemon
./libscript.sh install timescaledb latest
./libscript.sh start timescaledb
./libscript.sh status timescaledb
./libscript.sh logs timescaledb
./libscript.sh stop timescaledb
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install timescaledb latest
.\libscript.cmd start timescaledb
.\libscript.cmd status timescaledb
.\libscript.cmd stop timescaledb
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/timescaledb/<version>` (default `~/.libscript/timescaledb/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `TIMESCALEDB_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                          | Default  | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `TIMESCALEDB_INSTALL_METHOD` | How to install timescaledb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `TIMESCALEDB_VERSION`        | Specific version of timescaledb to install.                                                                                                          | `latest` | latest, lts      |
| `TIMESCALEDB_DOWNLOAD_URL`   | Override URL for downloading timescaledb binary or archive artifacts.                                                                                | `none`   |                  |
| `TIMESCALEDB_RELEASES_URL`   | Override URL for querying timescaledb available remote releases.                                                                                     | `none`   |                  |
| `TIMESCALEDB_LISTEN_PORT`    | TCP port on which the timescaledb service listens.                                                                                                   | `5432`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
