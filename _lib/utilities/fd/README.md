# fd (`_lib/utilities/fd/`)

## Overview

Simple, fast, and user-friendly alternative to find written in Rust with gitignore awareness.

- **Tier**: `T1` (`_lib/utilities/fd/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `fd`, `file-finder`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/fd/<version>)
./libscript.sh ls-remote fd
./libscript.sh install fd latest
./libscript.sh use fd latest
./libscript.sh which fd
./_lib/utilities/fd/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote fd
.\libscript.cmd install fd latest
.\libscript.cmd use fd latest
.\libscript.cmd which fd
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/fd/<version>`
  (default `~/.libscript/fd/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `FD_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                 | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FD_INSTALL_METHOD` | How to install fd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FD_VERSION`        | Specific version of fd to install.                                                                                                          | `latest`           | latest, lts      |
| `FD_DOWNLOAD_URL`   | Override URL for downloading fd binary or archive artifacts.                                                                                | `none`             |                  |
| `FD_RELEASES_URL`   | Override URL for querying fd available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
