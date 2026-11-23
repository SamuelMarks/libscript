# wait4x (`_lib/utilities/wait4x/`)

## Overview

Wait4X is a command-line tool that allows you to wait for various services or conditions to become
available before executing a command.

- **Tier**: `T1` (`_lib/utilities/wait4x/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`, `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/wait4x/<version>)
./libscript.sh ls-remote wait4x
./libscript.sh install wait4x latest
./libscript.sh use wait4x latest
./libscript.sh which wait4x
./_lib/utilities/wait4x/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote wait4x
.\libscript.cmd install wait4x latest
.\libscript.cmd use wait4x latest
.\libscript.cmd which wait4x
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/wait4x/<version>`
  (default `~/.libscript/wait4x/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `WAIT4X_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WAIT4X_INSTALL_METHOD` | Installation strategy for wait4x: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `WAIT4X_VERSION`        | Specific version of Wait4X to install.                                                                                                                   | `latest`           |                  |
| `WAIT4X_DOWNLOAD_URL`   | Override URL for downloading wait4x binary or archive artifacts.                                                                                         | `none`             |                  |
| `WAIT4X_RELEASES_URL`   | Override URL for querying wait4x available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
