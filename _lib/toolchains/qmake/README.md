# Qt qmake (`_lib/toolchains/qmake/`)

## Overview

Cross-platform Makefile generator from the Qt framework.

- **Tier**: `T1` (`_lib/toolchains/qmake/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/qmake/<version>)
./libscript.sh ls-remote qmake
./libscript.sh install qmake latest
./libscript.sh use qmake latest
./libscript.sh which qmake
./_lib/toolchains/qmake/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote qmake
.\libscript.cmd install qmake latest
.\libscript.cmd use qmake latest
.\libscript.cmd which qmake
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/qmake/<version>`
  (default `~/.libscript/qmake/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `QMAKE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `QMAKE_INSTALL_METHOD` | How to install qmake. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `QMAKE_VERSION`        | Specific version of qmake to install.                                                                                                          | `latest` | latest, 6.8.1    |
| `QMAKE_DOWNLOAD_URL`   | Override URL for downloading qmake binary or archive artifacts.                                                                                | `none`   |                  |
| `QMAKE_RELEASES_URL`   | Override URL for querying qmake available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
