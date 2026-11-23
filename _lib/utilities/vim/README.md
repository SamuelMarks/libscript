# Vim (`_lib/utilities/vim/`)

## Overview

Vi IMproved highly configurable modal text editor built for efficient code editing.

- **Tier**: `T1` (`_lib/utilities/vim/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `vim`, `editor`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/vim/<version>)
./libscript.sh ls-remote vim
./libscript.sh install vim latest
./libscript.sh use vim latest
./libscript.sh which vim
./_lib/utilities/vim/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote vim
.\libscript.cmd install vim latest
.\libscript.cmd use vim latest
.\libscript.cmd which vim
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/vim/<version>`
  (default `~/.libscript/vim/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `VIM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `VIM_INSTALL_METHOD` | How to install vim. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `VIM_VERSION`        | Specific version of vim to install.                                                                                                          | `latest` | latest, lts      |
| `VIM_DOWNLOAD_URL`   | Override URL for downloading vim binary or archive artifacts.                                                                                | `none`   |                  |
| `VIM_RELEASES_URL`   | Override URL for querying vim available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
