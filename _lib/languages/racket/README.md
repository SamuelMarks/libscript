# Racket (`_lib/languages/racket/`)

## Overview

General-purpose, multi-paradigm Lisp/Scheme language platform for language-oriented programming.

- **Tier**: `T1` (`_lib/languages/racket/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `racket`, `raco`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/racket/<version>)
./libscript.sh ls-remote racket
./libscript.sh install racket latest
./libscript.sh use racket latest
./libscript.sh which racket
./_lib/languages/racket/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote racket
.\libscript.cmd install racket latest
.\libscript.cmd use racket latest
.\libscript.cmd which racket
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/racket/<version>`
  (default `~/.libscript/racket/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `RACKET_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `RACKET_INSTALL_METHOD` | How to install racket. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `RACKET_VERSION`        | Specific version of racket to install.                                                                                                          | `latest` | latest, lts      |
| `RACKET_DOWNLOAD_URL`   | Override URL for downloading racket binary or archive artifacts.                                                                                | `none`   |                  |
| `RACKET_RELEASES_URL`   | Override URL for querying racket available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
