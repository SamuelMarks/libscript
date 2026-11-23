# YARPGen v2 Random C/C++17 Optimizer Fuzzing Generator (`_lib/toolchains/yarpgen/`)

## Overview

Standalone version manager and source builder for YARPGen v2, generating deterministic UB-free C and
C++17 differential checksum programs.

- **Tier**: `T1` (`_lib/toolchains/yarpgen/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/yarpgen/<version>)
./libscript.sh ls-remote yarpgen
./libscript.sh install yarpgen latest
./libscript.sh use yarpgen latest
./libscript.sh which yarpgen
./_lib/toolchains/yarpgen/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote yarpgen
.\libscript.cmd install yarpgen latest
.\libscript.cmd use yarpgen latest
.\libscript.cmd which yarpgen
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/yarpgen/<version>`
  (default `~/.libscript/yarpgen/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `YARPGEN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default       | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | ---------------- |
| `YARPGEN_INSTALL_METHOD` | How to install yarpgen. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `YARPGEN_VERSION`        | Specific version of yarpgen to install.                                                                                                          | `2.0`         | latest, lts      |
| `YARPGEN_DOWNLOAD_URL`   | Override URL for downloading yarpgen binary or archive artifacts.                                                                                | `none`        |                  |
| `YARPGEN_RELEASES_URL`   | Override URL for querying yarpgen available remote releases.                                                                                     | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
