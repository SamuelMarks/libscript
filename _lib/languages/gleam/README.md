# Gleam (`_lib/languages/gleam/`)

## Overview

Friendly type-safe functional language for building scalable systems on BEAM and JavaScript.

- **Tier**: `T1` (`_lib/languages/gleam/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/gleam/<version>)
./libscript.sh ls-remote gleam
./libscript.sh install gleam latest
./libscript.sh use gleam latest
./libscript.sh which gleam
./_lib/languages/gleam/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote gleam
.\libscript.cmd install gleam latest
.\libscript.cmd use gleam latest
.\libscript.cmd which gleam
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/gleam/<version>`
  (default `~/.libscript/gleam/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `GLEAM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GLEAM_INSTALL_METHOD` | How to install gleam. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GLEAM_VERSION`        | Specific version of gleam to install.                                                                                                          | `latest`           | latest, lts      |
| `GLEAM_DOWNLOAD_URL`   | Override URL for downloading gleam binary or archive artifacts.                                                                                | `none`             |                  |
| `GLEAM_RELEASES_URL`   | Override URL for querying gleam available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
