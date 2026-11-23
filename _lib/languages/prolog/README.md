# SWI-Prolog (`_lib/languages/prolog/`)

## Overview

Comprehensive SWI-Prolog (swipl) logic programming environment and compiler.

- **Tier**: `T1` (`_lib/languages/prolog/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `prolog`, `swipl`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/prolog/<version>)
./libscript.sh ls-remote prolog
./libscript.sh install prolog latest
./libscript.sh use prolog latest
./libscript.sh which prolog
./_lib/languages/prolog/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote prolog
.\libscript.cmd install prolog latest
.\libscript.cmd use prolog latest
.\libscript.cmd which prolog
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/prolog/<version>`
  (default `~/.libscript/prolog/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PROLOG_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PROLOG_INSTALL_METHOD` | How to install prolog. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `PROLOG_VERSION`        | Specific version of prolog to install.                                                                                                          | `latest` | latest, lts      |
| `PROLOG_DOWNLOAD_URL`   | Override URL for downloading prolog binary or archive artifacts.                                                                                | `none`   |                  |
| `PROLOG_RELEASES_URL`   | Override URL for querying prolog available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
