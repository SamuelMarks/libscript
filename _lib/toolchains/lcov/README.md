# LCOV Code Coverage Tooling (lcov / geninfo / genhtml) (`_lib/toolchains/lcov/`)

## Overview

Standalone version manager and installer for LCOV (lcov, geninfo, genhtml), extracting function,
line, and branch gcov coverage metrics.

- **Tier**: `T1` (`_lib/toolchains/lcov/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `lcov`, `geninfo`, `genhtml`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/lcov/<version>)
./libscript.sh ls-remote lcov
./libscript.sh install lcov latest
./libscript.sh use lcov latest
./libscript.sh which lcov
./_lib/toolchains/lcov/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote lcov
.\libscript.cmd install lcov latest
.\libscript.cmd use lcov latest
.\libscript.cmd which lcov
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/lcov/<version>`
  (default `~/.libscript/lcov/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LCOV_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `LCOV_INSTALL_METHOD` | How to install lcov. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `LCOV_VERSION`        | Specific version of lcov to install.                                                                                                          | `2.1`    | latest, lts      |
| `LCOV_DOWNLOAD_URL`   | Override URL for downloading lcov binary or archive artifacts.                                                                                | `none`   |                  |
| `LCOV_RELEASES_URL`   | Override URL for querying lcov available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
