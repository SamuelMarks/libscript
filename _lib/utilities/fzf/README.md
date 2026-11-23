# fzf (`_lib/utilities/fzf/`)

## Overview

General-purpose interactive command-line fuzzy finder written in Go.

- **Tier**: `T1` (`_lib/utilities/fzf/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `fzf`, `fuzzy-finder`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/fzf/<version>)
./libscript.sh ls-remote fzf
./libscript.sh install fzf latest
./libscript.sh use fzf latest
./libscript.sh which fzf
./_lib/utilities/fzf/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote fzf
.\libscript.cmd install fzf latest
.\libscript.cmd use fzf latest
.\libscript.cmd which fzf
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/fzf/<version>`
  (default `~/.libscript/fzf/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `FZF_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FZF_INSTALL_METHOD` | How to install fzf. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FZF_VERSION`        | Specific version of fzf to install.                                                                                                          | `latest`           | latest, lts      |
| `FZF_DOWNLOAD_URL`   | Override URL for downloading fzf binary or archive artifacts.                                                                                | `none`             |                  |
| `FZF_RELEASES_URL`   | Override URL for querying fzf available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
