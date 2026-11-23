# Meson (`_lib/toolchains/meson/`)

## Overview

The Meson high-productivity build system.

- **Tier**: `T1` (`_lib/toolchains/meson/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `meson`, `build-system`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/meson/<version>)
./libscript.sh ls-remote meson
./libscript.sh install meson latest
./libscript.sh use meson latest
./libscript.sh which meson
./_lib/toolchains/meson/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote meson
.\libscript.cmd install meson latest
.\libscript.cmd use meson latest
.\libscript.cmd which meson
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/meson/<version>`
  (default `~/.libscript/meson/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `MESON_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `MESON_INSTALL_METHOD` | How to install meson. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `MESON_VERSION`        | Specific version of meson to install.                                                                                                          | `latest` | latest, 1.6.1    |
| `MESON_DOWNLOAD_URL`   | Override URL for downloading meson binary or archive artifacts.                                                                                | `none`   |                  |
| `MESON_RELEASES_URL`   | Override URL for querying meson available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
