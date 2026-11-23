# Yasm (`_lib/toolchains/yasm/`)

## Overview

Modular BSD-licensed rewrite of the NASM x86/AMD64 assembler.

- **Tier**: `T1` (`_lib/toolchains/yasm/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `yasm`, `assembler`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/yasm/<version>)
./libscript.sh ls-remote yasm
./libscript.sh install yasm latest
./libscript.sh use yasm latest
./libscript.sh which yasm
./_lib/toolchains/yasm/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote yasm
.\libscript.cmd install yasm latest
.\libscript.cmd use yasm latest
.\libscript.cmd which yasm
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/yasm/<version>`
  (default `~/.libscript/yasm/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `YASM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `YASM_INSTALL_METHOD` | How to install yasm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `YASM_VERSION`        | Specific version of yasm to install.                                                                                                          | `latest` | latest, 1.3.0    |
| `YASM_DOWNLOAD_URL`   | Override URL for downloading yasm binary or archive artifacts.                                                                                | `none`   |                  |
| `YASM_RELEASES_URL`   | Override URL for querying yasm available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
