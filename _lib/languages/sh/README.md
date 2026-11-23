# Shell Toolchain (`_lib/languages/sh/`)

## Overview

POSIX-compliant shell environment.

- **Tier**: `T1` (`_lib/languages/sh/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `sh`, `toolchain`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/sh/<version>)
./libscript.sh ls-remote sh
./libscript.sh install sh latest
./libscript.sh use sh latest
./libscript.sh which sh
./_lib/languages/sh/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote sh
.\libscript.cmd install sh latest
.\libscript.cmd use sh latest
.\libscript.cmd which sh
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/sh/<version>`
  (default `~/.libscript/sh/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SH_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                          | Default            | Aliases/Examples |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SH_INSTALL_METHOD` | Installation strategy for sh: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `SH_VERSION`        | Version of Shell Toolchain to install                                                                                                                | `0.5.12`           |                  |
| `SH_DOWNLOAD_URL`   | Override URL for downloading sh binary or archive artifacts.                                                                                         | `none`             |                  |
| `SH_RELEASES_URL`   | Override URL for querying sh available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
