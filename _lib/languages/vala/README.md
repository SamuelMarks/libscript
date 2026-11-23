# Vala (`_lib/languages/vala/`)

## Overview

Object-oriented programming language with a self-hosting compiler (valac) generating C code for
GObject.

- **Tier**: `T1` (`_lib/languages/vala/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `vala`, `valac`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/vala/<version>)
./libscript.sh ls-remote vala
./libscript.sh install vala latest
./libscript.sh use vala latest
./libscript.sh which vala
./_lib/languages/vala/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote vala
.\libscript.cmd install vala latest
.\libscript.cmd use vala latest
.\libscript.cmd which vala
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/vala/<version>`
  (default `~/.libscript/vala/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `VALA_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `VALA_INSTALL_METHOD` | How to install vala. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `VALA_VERSION`        | Specific version of vala to install.                                                                                                          | `latest` | latest, lts      |
| `VALA_DOWNLOAD_URL`   | Override URL for downloading vala binary or archive artifacts.                                                                                | `none`   |                  |
| `VALA_RELEASES_URL`   | Override URL for querying vala available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
