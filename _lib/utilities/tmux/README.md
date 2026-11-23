# tmux (`_lib/utilities/tmux/`)

## Overview

tmux is a terminal multiplexer.

- **Tier**: `T1` (`_lib/utilities/tmux/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/tmux/<version>)
./libscript.sh ls-remote tmux
./libscript.sh install tmux latest
./libscript.sh use tmux latest
./libscript.sh which tmux
./_lib/utilities/tmux/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote tmux
.\libscript.cmd install tmux latest
.\libscript.cmd use tmux latest
.\libscript.cmd which tmux
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tmux/<version>`
  (default `~/.libscript/tmux/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TMUX_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default  | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `TMUX_INSTALL_METHOD` | Installation strategy for tmux: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `TMUX_VERSION`        | Specific version of tmux to install.                                                                                                                   | `latest` |                  |
| `TMUX_DOWNLOAD_URL`   | Override URL for downloading tmux binary or archive artifacts.                                                                                         | `none`   |                  |
| `TMUX_RELEASES_URL`   | Override URL for querying tmux available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
