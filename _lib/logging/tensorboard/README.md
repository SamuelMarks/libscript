# TensorBoard (`_lib/logging/tensorboard/`)

## Overview

TensorBoard is a suite of web applications for inspecting and understanding your TensorFlow runs and
graphs.

- **Tier**: `T1` (`_lib/logging/tensorboard/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `logging`, `tensorboard`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `freebsd`, `sunos`

## Usage

```sh
# Install and manage the tensorboard service daemon
./libscript.sh install tensorboard latest
./libscript.sh start tensorboard
./libscript.sh status tensorboard
./libscript.sh logs tensorboard
./libscript.sh stop tensorboard
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install tensorboard latest
.\libscript.cmd start tensorboard
.\libscript.cmd status tensorboard
.\libscript.cmd stop tensorboard
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/tensorboard/<version>` (default `~/.libscript/tensorboard/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `TENSORBOARD_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                           | Default            | Aliases/Examples |
| ---------------------------- | --------------------------------------------------------------------- | ------------------ | ---------------- |
| `TENSORBOARD_VERSION`        | Specific version of TensorBoard to install.                           | `latest`           | latest, stable   |
| `TENSORBOARD_INSTALL_METHOD` | How to install TensorBoard.                                           | `libscript_native` |                  |
| `TENSORBOARD_DOWNLOAD_URL`   | Override URL for downloading tensorboard binary or archive artifacts. | `none`             |                  |
| `TENSORBOARD_RELEASES_URL`   | Override URL for querying tensorboard available remote releases.      | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
