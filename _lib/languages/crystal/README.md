# Crystal (`_lib/languages/crystal/`)

## Overview

Statically type-checked compiled systems programming language with Ruby-inspired syntax.

- **Tier**: `T1` (`_lib/languages/crystal/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `crystal`, `shards`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/crystal/<version>)
./libscript.sh ls-remote crystal
./libscript.sh install crystal latest
./libscript.sh use crystal latest
./libscript.sh which crystal
./_lib/languages/crystal/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote crystal
.\libscript.cmd install crystal latest
.\libscript.cmd use crystal latest
.\libscript.cmd which crystal
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/crystal/<version>`
  (default `~/.libscript/crystal/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `CRYSTAL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `CRYSTAL_INSTALL_METHOD` | How to install crystal. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CRYSTAL_VERSION`        | Specific version of crystal to install.                                                                                                          | `latest`           | latest, lts      |
| `CRYSTAL_DOWNLOAD_URL`   | Override URL for downloading crystal binary or archive artifacts.                                                                                | `none`             |                  |
| `CRYSTAL_RELEASES_URL`   | Override URL for querying crystal available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
