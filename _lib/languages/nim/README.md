# Nim (`_lib/languages/nim/`)

## Overview

Statically typed compiled systems programming language combining Pythonic expressiveness with C
performance.

- **Tier**: `T1` (`_lib/languages/nim/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/nim/<version>)
./libscript.sh ls-remote nim
./libscript.sh install nim latest
./libscript.sh use nim latest
./libscript.sh which nim
./_lib/languages/nim/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote nim
.\libscript.cmd install nim latest
.\libscript.cmd use nim latest
.\libscript.cmd which nim
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/nim/<version>`
  (default `~/.libscript/nim/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `NIM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NIM_INSTALL_METHOD` | How to install nim. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `NIM_VERSION`        | Specific version of nim to install.                                                                                                          | `latest`           | latest, lts      |
| `NIM_DOWNLOAD_URL`   | Override URL for downloading nim binary or archive artifacts.                                                                                | `none`             |                  |
| `NIM_RELEASES_URL`   | Override URL for querying nim available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
