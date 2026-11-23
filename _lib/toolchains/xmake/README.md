# Xmake (`_lib/toolchains/xmake/`)

## Overview

A cross-platform Lua-based build utility.

- **Tier**: `T1` (`_lib/toolchains/xmake/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `xmake`, `build-system`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/xmake/<version>)
./libscript.sh ls-remote xmake
./libscript.sh install xmake latest
./libscript.sh use xmake latest
./libscript.sh which xmake
./_lib/toolchains/xmake/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote xmake
.\libscript.cmd install xmake latest
.\libscript.cmd use xmake latest
.\libscript.cmd which xmake
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/xmake/<version>`
  (default `~/.libscript/xmake/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `XMAKE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `XMAKE_INSTALL_METHOD` | How to install xmake. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `XMAKE_VERSION`        | Specific version of xmake to install.                                                                                                          | `latest` | latest, 2.9.7    |
| `XMAKE_DOWNLOAD_URL`   | Override URL for downloading xmake binary or archive artifacts.                                                                                | `none`   |                  |
| `XMAKE_RELEASES_URL`   | Override URL for querying xmake available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
