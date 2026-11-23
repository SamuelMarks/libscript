# Zig Toolchain (`_lib/languages/zig/`)

## Overview

A general-purpose programming language and toolchain for maintaining robust, optimal, and reusable
software.

- **Tier**: `T1` (`_lib/languages/zig/`)
- **Capabilities**: `userland-package`, `cross-toolchain`
- **Provides Virtual Capabilities**: `zig`, `toolchain`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/zig/<version>)
./libscript.sh ls-remote zig
./libscript.sh install zig latest
./libscript.sh use zig latest
./libscript.sh which zig
./_lib/languages/zig/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote zig
.\libscript.cmd install zig latest
.\libscript.cmd use zig latest
.\libscript.cmd which zig
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/zig/<version>`
  (default `~/.libscript/zig/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ZIG_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ZIG_VERSION`        | Specific version of zig to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `ZIG_INSTALL_METHOD` | Installation strategy for zig: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `ZIG_DOWNLOAD_URL`   | Override URL for downloading zig binary or archive artifacts.                                                                                         | `none`             |                  |
| `ZIG_RELEASES_URL`   | Override URL for querying zig available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
