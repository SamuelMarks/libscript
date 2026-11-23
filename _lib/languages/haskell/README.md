# GHC Haskell (`_lib/languages/haskell/`)

## Overview

Glasgow Haskell Compiler (ghc) purely functional programming language toolchain.

- **Tier**: `T1` (`_lib/languages/haskell/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `haskell`, `ghc`, `ghci`, `runghc`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/haskell/<version>)
./libscript.sh ls-remote haskell
./libscript.sh install haskell latest
./libscript.sh use haskell latest
./libscript.sh which haskell
./_lib/languages/haskell/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote haskell
.\libscript.cmd install haskell latest
.\libscript.cmd use haskell latest
.\libscript.cmd which haskell
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/haskell/<version>`
  (default `~/.libscript/haskell/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `HASKELL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `HASKELL_INSTALL_METHOD` | How to install haskell. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `HASKELL_VERSION`        | Specific version of haskell to install.                                                                                                          | `latest` | latest, lts      |
| `HASKELL_DOWNLOAD_URL`   | Override URL for downloading haskell binary or archive artifacts.                                                                                | `none`   |                  |
| `HASKELL_RELEASES_URL`   | Override URL for querying haskell available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
