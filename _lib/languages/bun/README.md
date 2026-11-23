# Bun Runtime (`_lib/languages/bun/`)

## Overview

A fast all-in-one JavaScript runtime, bundler, transpiler, and package manager.

- **Tier**: `T1` (`_lib/languages/bun/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `runtime`, `javascript`, `typescript`, `bun`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`, `windows`
- **Target OS Exclusions (`manifest.json`)**: `freebsd`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/bun/<version>)
./libscript.sh ls-remote bun
./libscript.sh install bun latest
./libscript.sh use bun latest
./libscript.sh which bun
./_lib/languages/bun/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote bun
.\libscript.cmd install bun latest
.\libscript.cmd use bun latest
.\libscript.cmd which bun
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/bun/<version>`
  (default `~/.libscript/bun/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `BUN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BUN_VERSION`        | Version of Bun demanded. Can be a specific version number like 'bun-v1.1.0' or an alias.                                                              | `latest`           | latest, canary   |
| `BUN_INSTALL_METHOD` | Installation strategy for bun: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `BUN_DOWNLOAD_URL`   | Override URL for downloading bun binary or archive artifacts.                                                                                         | `none`             |                  |
| `BUN_RELEASES_URL`   | Override URL for querying bun available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
