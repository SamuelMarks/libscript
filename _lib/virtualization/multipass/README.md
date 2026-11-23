# Canonical Multipass (`_lib/virtualization/multipass/`)

## Overview

Canonical Multipass lightweight Ubuntu VM orchestrator (multipass and multipassd) across Linux,
macOS, and Windows.

- **Tier**: `T1` (`_lib/virtualization/multipass/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `multipass`, `multipassd`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `macos`, `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/multipass/<version>)
./libscript.sh ls-remote multipass
./libscript.sh install multipass latest
./libscript.sh use multipass latest
./libscript.sh which multipass
./_lib/virtualization/multipass/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote multipass
.\libscript.cmd install multipass latest
.\libscript.cmd use multipass latest
.\libscript.cmd which multipass
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/multipass/<version>`
  (default `~/.libscript/multipass/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `MULTIPASS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MULTIPASS_INSTALL_METHOD` | How to install multipass. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `MULTIPASS_VERSION`        | Specific version of multipass to install.                                                                                                          | `latest`           | latest, stable   |
| `MULTIPASS_DOWNLOAD_URL`   | Override URL for downloading multipass binary or archive artifacts.                                                                                | `none`             |                  |
| `MULTIPASS_RELEASES_URL`   | Override URL for querying multipass available remote releases.                                                                                     | `none`             |                  |
| `MULTIPASS_LISTEN_PORT`    | TCP port on which the multipass service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
