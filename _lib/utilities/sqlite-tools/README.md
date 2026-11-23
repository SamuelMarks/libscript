# SQLite CLI Tools (`_lib/utilities/sqlite-tools/`)

## Overview

Official SQLite command-line bundle providing sqlite3 shell, sqldiff, and sqlite3_analyzer.

- **Tier**: `T1` (`_lib/utilities/sqlite-tools/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `sqlite-tools`, `sqldiff`, `sqlite3_analyzer`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/sqlite-tools/<version>)
./libscript.sh ls-remote sqlite-tools
./libscript.sh install sqlite-tools latest
./libscript.sh use sqlite-tools latest
./libscript.sh which sqlite-tools
./_lib/utilities/sqlite-tools/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote sqlite-tools
.\libscript.cmd install sqlite-tools latest
.\libscript.cmd use sqlite-tools latest
.\libscript.cmd which sqlite-tools
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/sqlite-tools/<version>` (default `~/.libscript/sqlite-tools/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `SQLITE_TOOLS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                                           | Default            | Aliases/Examples |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SQLITE_TOOLS_INSTALL_METHOD` | How to install sqlite-tools. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SQLITE_TOOLS_VERSION`        | Specific version of sqlite-tools to install.                                                                                                          | `latest`           | latest, lts      |
| `SQLITE_TOOLS_DOWNLOAD_URL`   | Override URL for downloading sqlite-tools binary or archive artifacts.                                                                                | `none`             |                  |
| `SQLITE_TOOLS_RELEASES_URL`   | Override URL for querying sqlite-tools available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
