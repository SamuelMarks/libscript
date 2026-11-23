# SCons (`_lib/toolchains/scons/`)

## Overview

Software construction tool configured with Python scripts.

- **Tier**: `T1` (`_lib/toolchains/scons/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `scons`, `build-system`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/scons/<version>)
./libscript.sh ls-remote scons
./libscript.sh install scons latest
./libscript.sh use scons latest
./libscript.sh which scons
./_lib/toolchains/scons/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote scons
.\libscript.cmd install scons latest
.\libscript.cmd use scons latest
.\libscript.cmd which scons
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/scons/<version>`
  (default `~/.libscript/scons/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SCONS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `SCONS_INSTALL_METHOD` | How to install scons. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `SCONS_VERSION`        | Specific version of scons to install.                                                                                                          | `latest` | latest, 4.8.1    |
| `SCONS_DOWNLOAD_URL`   | Override URL for downloading scons binary or archive artifacts.                                                                                | `none`   |                  |
| `SCONS_RELEASES_URL`   | Override URL for querying scons available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
