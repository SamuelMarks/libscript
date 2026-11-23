# Scheme (`_lib/languages/scheme/`)

## Overview

Chez Scheme and GNU Guile (scheme / guile) minimalist lexically scoped Lisp dialect.

- **Tier**: `T1` (`_lib/languages/scheme/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `scheme`, `guile`, `chez`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/scheme/<version>)
./libscript.sh ls-remote scheme
./libscript.sh install scheme latest
./libscript.sh use scheme latest
./libscript.sh which scheme
./_lib/languages/scheme/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote scheme
.\libscript.cmd install scheme latest
.\libscript.cmd use scheme latest
.\libscript.cmd which scheme
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/scheme/<version>`
  (default `~/.libscript/scheme/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SCHEME_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `SCHEME_INSTALL_METHOD` | How to install scheme. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `SCHEME_VERSION`        | Specific version of scheme to install.                                                                                                          | `latest` | latest, lts      |
| `SCHEME_DOWNLOAD_URL`   | Override URL for downloading scheme binary or archive artifacts.                                                                                | `none`   |                  |
| `SCHEME_RELEASES_URL`   | Override URL for querying scheme available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
