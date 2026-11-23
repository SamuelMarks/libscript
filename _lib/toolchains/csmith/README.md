# Csmith Random C11 Differential Testing Generator (`_lib/toolchains/csmith/`)

## Overview

Standalone version manager and source builder for Csmith, generating UB-free random C programs and
providing runtime checksum headers under CSMITH_HOME/include.

- **Tier**: `T1` (`_lib/toolchains/csmith/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/csmith/<version>)
./libscript.sh ls-remote csmith
./libscript.sh install csmith latest
./libscript.sh use csmith latest
./libscript.sh which csmith
./_lib/toolchains/csmith/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote csmith
.\libscript.cmd install csmith latest
.\libscript.cmd use csmith latest
.\libscript.cmd which csmith
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/csmith/<version>`
  (default `~/.libscript/csmith/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CSMITH_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default       | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `CSMITH_INSTALL_METHOD` | How to install csmith. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `CSMITH_VERSION`        | Specific version of csmith to install.                                                                                                          | `2.3.0`       | latest, lts      |
| `CSMITH_DOWNLOAD_URL`   | Override URL for downloading csmith binary or archive artifacts.                                                                                | `none`        |                  |
| `CSMITH_RELEASES_URL`   | Override URL for querying csmith available remote releases.                                                                                     | `none`        |                  |
| `CSMITH_HOME`           | Installation prefix containing bin/csmith and include/csmith.h runtime checksum headers.                                                        | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
