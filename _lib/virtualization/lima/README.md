# Lima Linux Virtual Machines (`_lib/virtualization/lima/`)

## Overview

Lima (limactl) Linux virtual machines with automatic file sharing, port forwarding, and
containerd/Docker support on macOS and Linux.

- **Tier**: `T1` (`_lib/virtualization/lima/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `lima`, `limactl`, `nerdctl.lima`
- **Target OS Whitelist (`manifest.json`)**: `macos`, `linux`, `freebsd`, `netbsd`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/lima/<version>)
./libscript.sh ls-remote lima
./libscript.sh install lima latest
./libscript.sh use lima latest
./libscript.sh which lima
./_lib/virtualization/lima/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote lima
.\libscript.cmd install lima latest
.\libscript.cmd use lima latest
.\libscript.cmd which lima
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/lima/<version>`
  (default `~/.libscript/lima/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LIMA_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIMA_INSTALL_METHOD` | How to install lima. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LIMA_VERSION`        | Specific version of lima to install.                                                                                                          | `latest`           | latest, stable   |
| `LIMA_DOWNLOAD_URL`   | Override URL for downloading lima binary or archive artifacts.                                                                                | `none`             |                  |
| `LIMA_RELEASES_URL`   | Override URL for querying lima available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
