# NASM (`_lib/toolchains/nasm/`)

## Overview

The Netwide Assembler portable x86 and x86-64 assembler.

- **Tier**: `T1` (`_lib/toolchains/nasm/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `nasm`, `assembler`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/nasm/<version>)
./libscript.sh ls-remote nasm
./libscript.sh install nasm latest
./libscript.sh use nasm latest
./libscript.sh which nasm
./_lib/toolchains/nasm/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote nasm
.\libscript.cmd install nasm latest
.\libscript.cmd use nasm latest
.\libscript.cmd which nasm
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/nasm/<version>`
  (default `~/.libscript/nasm/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `NASM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `NASM_INSTALL_METHOD` | How to install nasm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `NASM_VERSION`        | Specific version of nasm to install.                                                                                                          | `latest` | latest, 2.16.03  |
| `NASM_DOWNLOAD_URL`   | Override URL for downloading nasm binary or archive artifacts.                                                                                | `none`   |                  |
| `NASM_RELEASES_URL`   | Override URL for querying nasm available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
